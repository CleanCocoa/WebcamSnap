//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa
import AVFoundation

enum CaptureResult {
    case error(Error)
    case image(NSImage)
}

public enum WebcamError: Error, Equatable {
    case unknown(Error?)
    case sessionError(Error)
    case cameraSetupFailed
}

public func ==(lhs: WebcamError, rhs: WebcamError) -> Bool {

    switch (lhs, rhs) {
    case (.unknown, .unknown),
         (.sessionError, .sessionError),
         (.cameraSetupFailed, .cameraSetupFailed):
        return true

    default:
        return false
    }
}

class Webcam {

    let session: AVCaptureSession
    let stillImageOutput: AVCaptureStillImageOutput

    init() throws {

        let session = AVCaptureSession()
        session.sessionPreset = .medium

        let stillOutput = AVCaptureStillImageOutput()
        stillOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        session.addOutput(stillOutput)

        guard let device = AVCaptureDevice.default(for: .video)
            else { throw WebcamError.cameraSetupFailed }
        let input: AVCaptureDeviceInput

        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            throw WebcamError.cameraSetupFailed
        }

        guard session.canAddInput(input)
            else { throw WebcamError.sessionError("Cannot add input") }
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

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = hostingView.bounds

        hostingView.wantsLayer = true
        hostingView.layer?.addSublayer(previewLayer)
    }

    /// - parameter result: Callback after capturing the image. Dispatched on main queue.
    func captureImage(result: @escaping (CaptureResult) -> Void) {

        guard let connection = stillImageOutput.connection(with: .video) else {
            result(.error("Cannot capture still image"))
            return
        }
        stillImageOutput.captureStillImageAsynchronously(from: connection) { (imageBuffer: CMSampleBuffer?, error: Error?) in

            guard let imageBuffer = imageBuffer,
                let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer) else {
                DispatchQueue.main.async { result(.error("JPEG data could not be created")) }
                return
            }

            guard let image = NSImage(data: data) else {
                DispatchQueue.main.async { result(.error("NSImage conversion failed")) }
                return
            }

            DispatchQueue.main.async { result(.image(image)) }
        }
    }
}
