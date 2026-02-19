import Foundation
import MultipeerConnectivity
import UIKit

// MARK: - Transfer State Machine

enum TransferRole {
    case none
    case sender
    case receiver
}

enum TransferState: Equatable {
    case idle
    case advertising
    case browsing
    case connecting(String)
    case connected(String)
    case sending
    case receiving
    case sent
    case received
    case failed(String)
}

// MARK: - PeerTransferManager

@MainActor
final class PeerTransferManager: NSObject, ObservableObject {

    @Published var role: TransferRole = .none
    @Published var state: TransferState = .idle

    var onCardReceived: ((CardTransferPayload) -> Void)?

    private let serviceType = "ecocardshare" // ≤15 chars, lowercase, no underscores

    private var peerID: MCPeerID!
    // nonisolated(unsafe): MCSession is Obj-C thread-safe; needed so nonisolated delegates
    // can call invitationHandler/invitePeer without crossing the @MainActor boundary.
    nonisolated(unsafe) private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    override init() {
        super.init()
        // Append short UUID so two devices with the same name don't conflict
        let uniqueName = UIDevice.current.name + "-" + UUID().uuidString.prefix(4)
        peerID = MCPeerID(displayName: uniqueName)
        rebuildSession()
    }

    // MARK: - Session Lifecycle

    private func rebuildSession() {
        session?.disconnect()
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    // MARK: - Stop All

    func stopAll() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()
        role = .none
        state = .idle
    }

    // MARK: - Sender Mode

    func startSenderMode() {
        stopAll()
        rebuildSession()

        role = .sender
        state = .advertising

        let adv = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["app": "EcoCard"],
            serviceType: serviceType
        )
        adv.delegate = self
        advertiser = adv

        // Delay avoids NameDrop system overlay collision; capture adv directly (no self needed)
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            adv.startAdvertisingPeer()
        }
    }

    func stopSenderMode() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session.disconnect()
        role = .none
        state = .idle
    }

    // MARK: - Receiver Mode

    func startReceiverMode() {
        stopAll()
        rebuildSession()

        role = .receiver
        state = .browsing

        let br = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        br.delegate = self
        browser = br

        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            br.startBrowsingForPeers()
        }
    }

    func stopReceiverMode() {
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()
        role = .none
        state = .idle
    }

    // MARK: - Send Card

    func sendCard(_ payload: CardTransferPayload) {
        guard !session.connectedPeers.isEmpty else {
            state = .failed("No receiver connected")
            return
        }
        do {
            state = .sending
            let data = try JSONEncoder().encode(payload)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            state = .sent
        } catch {
            state = .failed("Send failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Sender)

extension PeerTransferManager: @preconcurrency MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        // ✅ Call immediately on callback thread — do NOT hop actors before invitationHandler
        invitationHandler(true, self.session)
        let name = peerID.displayName
        Task { @MainActor in self.state = .connecting(name) }
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        print("❌ Advertiser failed:", error)
        let message = error.localizedDescription
        Task { @MainActor in
            self.state = .failed("Advertiser error: \(message)")
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if let adv = self.advertiser {
                    adv.stopAdvertisingPeer()
                    adv.startAdvertisingPeer()
                }
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Receiver)

extension PeerTransferManager: @preconcurrency MCNearbyServiceBrowserDelegate {

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        print("✅ Found peer:", peerID.displayName)
        // ✅ Invite immediately on callback thread — do NOT pass browser/peerID across actors
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 12)
        let name = peerID.displayName
        Task { @MainActor in self.state = .connecting(name) }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        print("❌ Browser failed:", error)
        let message = error.localizedDescription
        Task { @MainActor in
            self.state = .failed("Browse error: \(message)")
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if let br = self.browser {
                    br.stopBrowsingForPeers()
                    br.startBrowsingForPeers()
                }
            }
        }
    }
}

// MARK: - MCSessionDelegate (Both)

extension PeerTransferManager: @preconcurrency MCSessionDelegate {

    nonisolated func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        let name = peerID.displayName
        print("🔗 Peer \(name) state changed:", state.rawValue)
        Task { @MainActor in
            switch state {
            case .connected:    self.state = .connected(name)
            case .connecting:   self.state = .connecting(name)
            case .notConnected: self.state = .idle
            @unknown default:   break
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        do {
            let payload = try JSONDecoder().decode(CardTransferPayload.self, from: data)
            Task { @MainActor in
                self.state = .received
                self.onCardReceived?(payload)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {
            let msg = error.localizedDescription
            Task { @MainActor in self.state = .failed("Decode failed: \(msg)") }
        }
    }

    // Required stubs
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
