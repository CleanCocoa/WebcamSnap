//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa
import Quartz

// Make Strings throwable
extension String: Error {}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        self.currentTool = .pan
    }

    // MARK: -

    lazy var snapPicture: SnapPicture = SnapPicture()
    @IBOutlet weak var resultImageView: IKImageView!
    @IBOutlet weak var placeholderLabel: NSTextField!
    @IBOutlet weak var toolsSegmentedControl: NSSegmentedControl!

    @IBAction func newSnap(_ sender: Any) {

        snapPicture.showSheet(hostingWindow: window) { result in
            switch result {
            case .cancel: break
            case .error(let error): print("error taking picture: \(error)")
            case .picture(let image):
                self.placeholderLabel.isHidden = true
                self.resultImageView.setImage(
                    image.cgImage(forProposedRect: nil, context: nil, hints: nil),
                    imageProperties: [:])
            }
        }
    }

    enum Tool: Int {
        case pan = 0
        case crop = 1
        case rotate = 2

        var toolMode: String {
            switch self {
            case .pan: return IKToolModeMove
            case .crop: return IKToolModeCrop
            case .rotate: return IKToolModeRotate
            }
        }
    }

    var currentTool: Tool! {
        didSet {
            resultImageView.currentToolMode = currentTool.toolMode
            toolsSegmentedControl.selectedSegment = currentTool.rawValue
        }
    }

    @IBAction func switchTool(_ sender: Any) {

        func rawToolValue(control: Any) -> Int? {

            switch control {
            case let segmentedControl as NSSegmentedControl:
                return segmentedControl.selectedSegment

            default: return nil
            }
        }

        guard let rawValue = rawToolValue(control: sender),
            let tool = Tool(rawValue: rawValue)
            else { assertionFailure("Couldn't figure out tool."); return }

        resultImageView.currentToolMode = tool.toolMode
    }
}

