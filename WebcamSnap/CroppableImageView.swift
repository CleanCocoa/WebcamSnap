//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

public class CroppableImageView: NSImageView {

    public var cancel: (() -> Void)?
    public var crop: ((NSImage) -> Void)?

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
            || handleEnter(event: event)

        guard didHandleEvent else { super.keyDown(with: event); return }
    }

    fileprivate func handleEnter(event: NSEvent) -> Bool {

        guard let cropMarker = self.cropMarker,

            let crop = self.crop,
            event.keyCode == 36 ||
            event.keyCode == 76,

            let image = self.image
            else { return false }

        let imageSize = image.size
        let drawingRect = self.bounds

        let diff: (factor: CGFloat, offset: NSPoint) = { () -> (CGFloat, NSPoint) in
            let drawingAspect = drawingRect.width / drawingRect.height
            let imageAspect = imageSize.width / imageSize.height
            if imageAspect > drawingAspect {
                // Full width, cropped height
                let factor = imageSize.width / drawingRect.width

                let imageHeightInFrame = imageSize.height / factor
                let offsetY = (drawingRect.height - imageHeightInFrame) / 2
                let offset = NSPoint(x: 0, y: -offsetY)

                return (factor, offset)
            } else {
                // Full height, cropped width
                let factor = imageSize.height / drawingRect.height

                let imageWidthInFrame = imageSize.width / factor
                let offsetX = (drawingRect.width - imageWidthInFrame) / 2
                let offset = NSPoint(x: -offsetX, y: 0)

                return (factor, offset)
            }
        }()
        let scaling = CGAffineTransform(scaleX: diff.factor, y: diff.factor)
        let translation = CGAffineTransform(translationX: diff.offset.x, y: diff.offset.y)
        let selectionRect = cropMarker.selectedRect.applying(translation).applying(scaling)

        guard let representation = image.bestRepresentation(for: selectionRect, context: nil, hints: nil)
            else { return false }

        let result = NSImage(size: selectionRect.size, flipped: false) { _ -> Bool in
            representation.draw(in: NSRect(x: 0, y: 0, width: selectionRect.width, height: selectionRect.height), from: selectionRect, operation: .sourceOver, fraction: 1, respectFlipped: false, hints: nil)
        }

        crop(result)

        return true
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
