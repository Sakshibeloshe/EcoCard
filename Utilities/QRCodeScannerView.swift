import SwiftUI
import AVFoundation

/// A camera-based QR code scanner wrapped as a SwiftUI view.
///
/// **Swift 6 concurrency notes:**
/// • `ScannerUIView` is a UIKit class — it runs on the main actor.
/// • The AVFoundation delegate callback is delivered on `.main` queue
///   (configured in `setMetadataObjectsDelegate(_:queue:)`), so no
///   actor-hopping is needed inside `metadataOutput(_:didOutput:from:)`.
/// • `AVCaptureSession.startRunning()` is a blocking call that must run
///   on a background thread; we use `Task.detached` for that.
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
/// Main-actor isolated (inherits from UIView).
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
            // Off screen — stop the session
            let session = captureSession
            Task.detached(priority: .userInitiated) {
                session?.stopRunning()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    // MARK: Session Setup

    private func setupSession() {
        guard captureSession == nil else { return }   // already set up
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

        // Deliver metadata callbacks on the main queue — matches @MainActor
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = bounds
        preview.videoGravity = .resizeAspectFill
        layer.insertSublayer(preview, at: 0)
        previewLayer = preview
        captureSession = session

        // startRunning() blocks — run it off the main thread
        Task.detached(priority: .userInitiated) {
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
