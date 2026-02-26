import SwiftUI
import AVFoundation

/// A camera-based QR code scanner wrapped as a SwiftUI view.
///
/// **Swift 6 concurrency notes:**
/// • `ScannerUIView` is a UIKit class — @MainActor isolated.
/// • AVFoundation metadata callbacks are delivered on `.main` queue
///   (configured in `setMetadataObjectsDelegate(_:queue:)`).
/// • `AVCaptureSession.startRunning()` blocks; it runs in `Task.detached`.
///   The session is captured as a local `let` *before* the detached task so
///   Swift sees a Sendable value crossing the boundary, not a @MainActor property.
@MainActor
struct QRCodeScannerView: UIViewRepresentable {

    var onScan: @MainActor (String) -> Void

    func makeUIView(context: Context) -> ScannerUIView {
        let view = ScannerUIView()
        view.onScan = onScan
        return view
    }

    func updateUIView(_ uiView: ScannerUIView, context: Context) {
        uiView.onScan = onScan
    }

    func makeCoordinator() -> Void { () }
}

// MARK: - ScannerUIView

/// UIKit view that owns the AVCaptureSession.
/// @MainActor isolated (inherits from UIView).
@MainActor
final class ScannerUIView: UIView {

    var onScan: (@MainActor (String) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScanned: String = ""

    // MARK: Lifecycle

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            setupSession()
        } else {
            // Capture the session as a local Sendable value *before* the
            // detached task so we never send a @MainActor-isolated property
            // across actor boundaries.
            if let session = captureSession {
                DispatchQueue.global(qos: .userInitiated).async {
                    session.stopRunning()
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    // MARK: Session Setup

    private func setupSession() {
        guard captureSession == nil else { return }
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else {
            print("[Scanner] Camera access denied"); return
        }

        let session = AVCaptureSession()

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        // Deliver metadata callbacks on the main queue — matches @MainActor.
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = bounds
        preview.videoGravity = .resizeAspectFill
        layer.insertSublayer(preview, at: 0)
        previewLayer = preview
        captureSession = session

        // startRunning() blocks — off-load to GCD.
        // GCD doesn't participate in Swift's actor/Sendable analysis,
        // so AVCaptureSession (which is not Sendable) crosses safely.
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
// Called on .main queue (configured above), so we're already on @MainActor.

extension ScannerUIView: AVCaptureMetadataOutputObjectsDelegate {

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput metadataObjects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        guard
            let obj    = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            obj.type  == .qr,
            let string = obj.stringValue
        else { return }

        // We asked for callbacks on .main, so hop to MainActor cleanly.
        Task { @MainActor [weak self] in
            guard let self, string != self.lastScanned else { return }
            self.lastScanned = string
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.onScan?(string)

            // Reset debounce after 3 s
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.lastScanned = ""
        }
    }
}
