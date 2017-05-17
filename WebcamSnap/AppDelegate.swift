//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

// Make Strings throwable
extension String: Error {}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        resultImageView.wantsLayer = true
        resultImageView.layer?.backgroundColor = NSColor.darkGray.cgColor
        resultImageView.cancel = { [weak self] in
            self?.cropToggleButton.state = NSOffState
            self?.toggleCropping(nil)
        }
    }

    // MARK: -

    lazy var snapPicture: SnapPicture = SnapPicture()
    @IBOutlet weak var resultImageView: CroppableImageView!
    @IBOutlet weak var placeholderLabel: NSTextField!

    @IBOutlet weak var cropToggleButton: NSButton!
    @IBOutlet weak var aspectRatioCheckBox: NSButton!

    @IBAction func toggleCropping(_ sender: Any?) {

        let enabled = (cropToggleButton.state == NSOnState)
        aspectRatioCheckBox.isEnabled = enabled

        switch enabled {
        case true:
            resultImageView.startCropping()
        case false:
            resultImageView.cancelCropping()
        }

        makeImageViewFirstResponder()
    }

    private func makeImageViewFirstResponder() {

        self.window.makeFirstResponder(resultImageView)
    }

    @IBAction func toggleAspectRatio(_ sender: Any?) {

        let lockRatio = (aspectRatioCheckBox.state == NSOnState)

        switch lockRatio {
        case true:
            resultImageView.enableAspectRatio(sender)
        case false:
            resultImageView.disableAspectRatio(sender)
        }

        makeImageViewFirstResponder()
    }

    @IBAction func newSnap(_ sender: Any?) {

        snapPicture.showSheet(hostingWindow: window) { result in
            switch result {
            case .cancel: break
            case .error(let error): print("error taking picture: \(error)")
            case .picture(let image):
                self.placeholderLabel.isHidden = true
                self.resultImageView.image = image
                self.makeImageViewFirstResponder()
            }
        }
    }
}
