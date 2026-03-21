import SwiftUI
import AVFoundation

// MARK: - Barcode Scanner View Delegate

struct BarcodeScannerView: UIViewControllerRepresentable {
    
    var onDetect: (String) -> Void
    var onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        var parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func scannerViewController(_ vc: ScannerViewController, didDetectBarcode code: String) {
            parent.onDetect(code)
        }
        
        func scannerViewControllerDidCancel(_ vc: ScannerViewController) {
            parent.onCancel()
        }
    }
}

// MARK: - UIKit Scanner View Controller

protocol ScannerViewControllerDelegate: AnyObject {
    func scannerViewController(_ vc: ScannerViewController, didDetectBarcode code: String)
    func scannerViewControllerDidCancel(_ vc: ScannerViewController)
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    weak var delegate: ScannerViewControllerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isScanning = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        
        setupCamera()
        setupOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            failed()
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // Support all common barcode types used on food packaging
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .code93]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    private func setupOverlay() {
        // Semi-transparent overlay with a cutout
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Create the cutout square for scanning area
        let path = CGMutablePath()
        path.addRect(view.bounds)
        
        let scanSize: CGFloat = 250
        let scanRect = CGRect(
            x: view.bounds.midX - (scanSize / 2),
            y: view.bounds.midY - (scanSize / 2),
            width: scanSize,
            height: scanSize
        )
        
        path.addRoundedRect(in: scanRect, cornerWidth: 16, cornerHeight: 16)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
        view.addSubview(overlayView)
        
        // Outline box
        let frameView = UIView(frame: scanRect)
        frameView.layer.borderColor = UIColor.systemGreen.cgColor
        frameView.layer.borderWidth = 3
        frameView.layer.cornerRadius = 16
        frameView.backgroundColor = .clear
        view.addSubview(frameView)
        
        // Instructions Text
        let label = UILabel()
        label.text = "Align barcode within the square"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: scanRect.maxY + 24, width: view.bounds.width, height: 30)
        view.addSubview(label)
        
        // Close Button
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.frame = CGRect(x: 20, y: 50, width: 44, height: 44)
        closeBtn.contentVerticalAlignment = .fill
        closeBtn.contentHorizontalAlignment = .fill
        closeBtn.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        view.addSubview(closeBtn)
    }
    
    // MARK: - Delegate Actions
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a barcode from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard isScanning else { return }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Provide haptic feedback
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Stop scanning to avoid double-firing
            isScanning = false
            captureSession.stopRunning()
            
            delegate?.scannerViewController(self, didDetectBarcode: stringValue)
        }
    }
    
    @objc private func didTapClose() {
        delegate?.scannerViewControllerDidCancel(self)
    }
    
    // Support rotation
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
