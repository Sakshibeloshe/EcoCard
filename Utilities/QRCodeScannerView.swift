import SwiftUI
import AVFoundation

/// A camera-based QR code scanner view.
///
/// Calls `onScan` with the raw decoded string when a QR code is detected.
/// Designed to be embedded inside another SwiftUI view.
struct QRCodeScannerView: UIViewRepresentable {

    var onScan: (String) -> Void

    func makeUIView(context: Context) -> ScannerUIView {
        let view = ScannerUIView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: ScannerUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onScan: (String) -> Void
        private var lastScanned: String = ""

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                             didOutput metadataObjects: [AVMetadataObject],
                             from connection: AVCaptureConnection) {
            guard
                let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                obj.type == .qr,
                let string = obj.stringValue
            else { return }

            Task { @MainActor [weak self] in
                guard let self else { return }
                
                guard string != self.lastScanned else { return }
                self.lastScanned = string
                
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.onScan(string)

                // Allow re-scanning after 3 s
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run { [weak self] in
                        self?.lastScanned = ""
                    }
                }
            }
        }
    }
}

// MARK: - UIView wrapper

final class ScannerUIView: UIView {

    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil { setupSession() }
        else { captureSession?.stopRunning() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    private func setupSession() {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else { return }

        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        output.setMetadataObjectsDelegate(delegate, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = bounds
        preview.videoGravity = .resizeAspectFill
        layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
}
