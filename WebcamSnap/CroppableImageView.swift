//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

public class CroppableImageView: NSImageView {

    public var cancel: (() -> Void)?

    public override var acceptsFirstResponder: Bool { return true }

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


    // MARK: - Keyboard Control

    public override func keyDown(with event: NSEvent) {

        let didHandleEvent = handleEscape(event: event)
            || handleSelectAll(event: event)
            || handleTranslation(event: event)

        guard didHandleEvent else { super.keyDown(with: event); return }
    }

    fileprivate func handleEscape(event: NSEvent) -> Bool {

        guard let cancel = self.cancel,
            // Escape Key
            event.keyCode == 53
            // ⌘.
            || (event.characters?.characters.first == "."
                && event.modifierFlags.contains(.command))
            else { return false }

        cancel()
        return true
    }

    fileprivate func handleSelectAll(event: NSEvent) -> Bool {

        guard let cropMarker = self.cropMarker else { return false }

        guard event.characters?.lowercased().characters.first == "a"
            && event.modifierFlags.contains(.command)
            else { return false}

        cropMarker.selectedRect = self.bounds
        setNeedsDisplay()

        return true
    }

    enum Direction: UInt16 {
        case left = 123
        case right = 124
        case down = 125
        case up = 126

        var translation: NSPoint {
            switch self {
            case .left:  return NSPoint(x: -1, y: 0)
            case .right: return NSPoint(x: 1, y: 0)
            case .up:    return NSPoint(x: 0, y: 1)
            case .down:  return NSPoint(x: 0, y: -1)
            }
        }
    }

    fileprivate func handleTranslation(event: NSEvent) -> Bool {

        guard let direction = Direction(rawValue: event.keyCode),
            let cropMarker = self.cropMarker else { return false }

        let speed: CGAffineTransform = {
            if event.modifierFlags.contains(.shift) {
                return CGAffineTransform(scaleX: 20, y: 20)
            }

            return CGAffineTransform(scaleX: 2, y: 2)
        }()

        let translation = direction.translation.applying(speed)

        cropMarker.translateBy(x: translation.x, y: translation.y, in: self)
        setNeedsDisplay()

        return true
    }

    // MARK: - Actions

    @IBAction public func enableAspectRatio(_ sender: Any?) {

        guard let cropMarker = self.cropMarker else { return }

        cropMarker.aspectRatio = NSSize(width: 100, height: 100)
        cropMarker.isLockingAspectRatio = true

        setNeedsDisplay()
    }

    @IBAction public func disableAspectRatio(_ sender: Any?) {

        guard let cropMarker = self.cropMarker else { return }

        cropMarker.isLockingAspectRatio = false

        setNeedsDisplay()
    }
}
