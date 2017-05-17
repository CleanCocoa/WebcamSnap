//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

// Make Strings throwable
extension String: Error {}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

    }

    // MARK: -

    @IBOutlet weak var resultImageView: NSImageView!
    @IBOutlet weak var previewView: NSView!
    lazy var snapWindowController: SnapWindowController = SnapWindowController()


    @IBAction func newSnap(_ sender: Any) {

        snapWindowController.showAsSheet(hostingWindow: window) { result in
            switch result {
            case .cancel: break
            case .error(let error): print("error taking picture: \(error)")
            case .picture(let image): self.resultImageView.image = image
            }
        }
    }
}

