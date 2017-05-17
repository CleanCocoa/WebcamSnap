//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa
import AVFoundation

extension String: Error {}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

    }

    // MARK: -

    @IBOutlet weak var resultImageView: NSImageView!

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

        func captureImage(result: @escaping (NSImage?, Error?) -> Void) {

            let connection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo)
            stillImageOutput.captureStillImageAsynchronously(from: connection) { (imageBuffer: CMSampleBuffer?, error: Error?) in

                guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer) else {
                    result(nil, "JPEG data could not be created")
                    return
                }

                guard let image = NSImage(data: data) else {
                    result(nil, "NSImage conversion failed")
                    return
                }

                result(image, nil)
            }
        }
    }

    var session: Webcam?

    @IBAction func newSnap(_ sender: Any) {

        do {
            self.session = try Webcam()
        } catch {
            print("session setup failed")
            return
        }

        guard let webcam = session else { return }

        webcam.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {

            webcam.captureImage(result: { (image, error) in

                defer {
                    DispatchQueue.main.async {
                        webcam.stop()
                    }
                }

                if let error = error {
                    print("\(error)")
                    return
                }

                guard let image = image else {
                    print("no image")
                    return
                }

                DispatchQueue.main.async {
                    self.resultImageView.image = image
                }
            })
        }
    }
}

