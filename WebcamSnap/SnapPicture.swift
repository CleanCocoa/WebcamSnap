//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

public enum SnapResult {
    case cancel
    case error(Error?)
    case picture(NSImage)
}

public class SnapPicture {

    init() { }
    
    lazy var snapWindowController: SnapWindowController = SnapWindowController()

    public func showSheet(hostingWindow: NSWindow, completion: @escaping (SnapResult) -> Void) {

        snapWindowController.showAsSheet(hostingWindow: hostingWindow, completion: completion)
    }
}
