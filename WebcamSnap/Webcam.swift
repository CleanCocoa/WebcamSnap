//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa
import AVFoundation

class Webcam {

    let session: AVCaptureSession
    let stillImageOutput: AVCaptureStillImageOutput

    init() throws {

        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetMedium

        let stillOutput = AVCaptureStillImageOutput()
        stillOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        session.addOutput(stillOutput)

        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw "Cannot add input" }
        session.addInput(input)

        self.session = session
        self.stillImageOutput = stillOutput
    }

    func start() {
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }

    deinit {
        if session.isRunning { stop() }
    }

    func showPreview(in hostingView: NSView) {

        guard let previewLayer = AVCaptureVideoPreviewLayer(session: session) else { return }
        previewLayer.frame = hostingView.bounds

        hostingView.wantsLayer = true
        hostingView.layer?.addSublayer(previewLayer)
    }

    /// - parameter result: Callback after capturing the image. Dispatched on main queue.
    func captureImage(result: @escaping (NSImage?, Error?) -> Void) {

        let connection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo)
        stillImageOutput.captureStillImageAsynchronously(from: connection) { (imageBuffer: CMSampleBuffer?, error: Error?) in

            guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer) else {
                DispatchQueue.main.async { result(nil, "JPEG data could not be created") }
                return
            }

            guard let image = NSImage(data: data) else {
                DispatchQueue.main.async { result(nil, "NSImage conversion failed") }
                return
            }

            DispatchQueue.main.async { result(image, nil) }
        }
    }
}
