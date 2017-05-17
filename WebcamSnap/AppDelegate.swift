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
    }

    // MARK: -

    lazy var snapPicture: SnapPicture = SnapPicture()
    @IBOutlet weak var resultImageView: CroppableImageView!
    @IBOutlet weak var placeholderLabel: NSTextField!

    @IBAction func newSnap(_ sender: Any?) {

        snapPicture.showSheet(hostingWindow: window) { result in
            switch result {
            case .cancel: break
            case .error(let error): print("error taking picture: \(error)")
            case .picture(let image):
                self.replaceImage(image: image)
            }
        }
    }

    fileprivate func replaceImage(image: NSImage) {

        resultImageView.image = image
        placeholderLabel.isHidden = true
    }
}
