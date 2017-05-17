//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

class SnapWindowController: NSWindowController {

    convenience init() {
        self.init(windowNibName: "SnapWindowController")
    }

    @IBOutlet weak var previewView: NSView!
    var webcam: Webcam?

    override func windowDidLoad() {

        super.windowDidLoad()
        previewView.wantsLayer = true
        previewView.layer?.backgroundColor = NSColor.black.cgColor
    }


    // MARK: Actions

    @IBAction func snap(_ sender: Any) {

        guard let webcam = self.webcam else { return }

        webcam.captureImage(result: { (image, error) in

            if let error = error {
                print("\(error)")
                return
            }

            guard let image = image else {
                print("no image")
                return
            }

            self.finish(image: image)
        })
    }

    @IBAction func cancel(_ sender: Any) {

        result = .cancel
        closeSheet()
    }


    // MARK: - Window-as-Sheet Management

    var result: SnapResult?

    func showAsSheet(hostingWindow: NSWindow, completion: @escaping (SnapResult) -> Void) {

        guard let window = self.window else { preconditionFailure("expected window outlet") }

        hostingWindow.beginSheet(window) { _ in

            let result = self.result ?? .error("No result.")
            completion(result)
        }

        do {
            self.webcam = try Webcam()
        } catch {
            self.result = .error("Webcam setup failed.")
            closeSheet()
            return
        }

        webcam?.start()
        webcam?.showPreview(in: previewView)
    }

    func finish(image: NSImage) {

        result = .picture(image)
        closeSheet()
    }

    func closeSheet(returnCode: NSModalResponse = NSModalResponseOK) {

        guard let window = self.window else { preconditionFailure("expected window outlet") }

        window.sheetParent?.endSheet(window, returnCode: returnCode)
    }
}
