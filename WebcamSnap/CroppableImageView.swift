//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

public class CroppableImageView: NSImageView {

    public func startCropping() {

        self.cropMarker = {
            let cropMarker = SCSelectionBorder()
            cropMarker.selectedRect = NSMakeRect(100, 100, 200, 200)
            cropMarker.fillColor = self.croppedFillColor
            return cropMarker
        }()
    }

    public func cancelCropping() {

        self.cropMarker = nil
    }

    fileprivate(set) var cropMarker: SCSelectionBorder? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    public var croppedFillColor: NSColor = NSColor.init(calibratedWhite: 0, alpha: 0.7) {
        didSet {
            cropMarker?.fillColor = croppedFillColor
        }
    }

    public override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)

        guard let cropMarker = self.cropMarker else { return }

        cropMarker.drawContent(in: self)
    }

    public override func mouseDown(with event: NSEvent) {

        guard let cropMarker = self.cropMarker else { return }

        let lastLocation = self.convert(event.locationInWindow, from: nil)
        cropMarker.selectAndTrackMouse(with: event, at: lastLocation, in: self)
    }

    @IBAction public func enableAspectRatio(_ sender: Any) {

        guard let cropMarker = self.cropMarker else { return }

        cropMarker.aspectRatio = NSSize(width: 100, height: 100)
        cropMarker.isLockingAspectRatio = true

        setNeedsDisplay()
    }

    @IBAction public func disableAspectRatio(_ sender: Any) {

        guard let cropMarker = self.cropMarker else { return }

        cropMarker.isLockingAspectRatio = false

        setNeedsDisplay()
    }
}
