//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa
import WebcamSnap

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        resultImageView.wantsLayer = true
        resultImageView.layer?.backgroundColor = NSColor.darkGray.cgColor
    }

    // MARK: -

    var snapPicture: SnapPicture!
    @IBOutlet weak var resultImageView: CroppableImageView!
    @IBOutlet weak var placeholderLabel: NSTextField!

    @IBAction func newSnap(_ sender: Any?) {

        self.snapPicture = SnapPicture()
        self.snapPicture.showSheet(hostingWindow: window) { result in
            switch result {
            case .cancel:
                // Ignore canceling
                break

            case .error(let webcamError as WebcamError)
                where webcamError == .cameraSetupFailed:
                self.showWebcamNotFoundAlert()

            case .error(let error):
                print("error taking picture: \(error)")

            case .picture(let image):
                self.replaceImage(image: image)
            }
        }
    }

    fileprivate func showWebcamNotFoundAlert() {

        let alert = NSAlert()
        alert.messageText = "No camera found"
        alert.addButton(withTitle: "Abort")
        alert.runModal()
    }

    fileprivate func replaceImage(image: NSImage) {

        resultImageView.image = image
        placeholderLabel.isHidden = true
    }
}
