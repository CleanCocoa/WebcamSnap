//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

class SnapWindowController: NSWindowController {

    convenience init() {
        self.init(windowNibName: "SnapWindowController")
    }

    var webcam: Webcam?
    @IBOutlet weak var takePictureButton: NSButton!
    @IBOutlet weak var cancelTakingPictureButton: NSButton!
    @IBOutlet weak var previewView: NSView!


    @IBOutlet weak var resultImageView: CroppableImageView!
    @IBOutlet weak var editingControlsView: NSView!

    @IBOutlet weak var cropToggleButton: NSButton!
    @IBOutlet weak var cropControlsView: NSView!
    @IBOutlet weak var aspectRatioCheckBox: NSButton!
    @IBOutlet weak var applyCropButton: NSButton!

    @IBOutlet weak var useImageButton: NSButton!
    @IBOutlet weak var cancelUsingImageButton: NSButton!
    

    override func windowDidLoad() {

        super.windowDidLoad()

        window?.contentView?.wantsLayer = true
        window?.contentView?.layer?.backgroundColor = NSColor.black.cgColor

        previewView.wantsLayer = true
        previewView.layer?.backgroundColor = NSColor.black.cgColor

        resultImageView.isEnabled = false
        resultImageView.isHidden = true
        previewView.alphaValue = 1.0
        editingControlsView.alphaValue = 0.0
        cropToggleButton.isEnabled = false
        aspectRatioCheckBox.isEnabled = false
        applyCropButton.isEnabled = false

        cancelUsingImageButton.isEnabled = false
        useImageButton.isEnabled = false

        resultImageView.abortCropping = { [weak self] in
            self?.resetCropping()
        }
        resultImageView.crop = { [weak self] in
            self?.replaceImage(image: $0)
        }
        resultImageView.pick = { [weak self] in
            self?.pickImage(image: $0)
        }
        resultImageView.cancel = { [weak self] in
            self?.cancelOperation(nil)
            return ()
        }
    }


    // MARK: - Actions

    // MARK: Snapping 

    @IBAction func snap(_ sender: Any) {

        guard let webcam = self.webcam else { return }

        webcam.captureImage(result: { result in

            switch result {
            case .error(let error): self.abort(error: error)
            case .image(let image): self.finishSnapping(image: image)
            }
        })
    }

    func finishSnapping(image: NSImage) {

        result = .picture(image)

        resultImageView.image = image
        resultImageView.isEnabled = true
        resultImageView.isHidden = false
        editingControlsView.isHidden = false

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true

            cancelTakingPictureButton.alphaValue = 0.0
            takePictureButton.alphaValue = 0.0
            previewView.alphaValue = 0.0
            editingControlsView.alphaValue = 1.0

            window?.contentView?.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }, completionHandler: {
            self.takePictureButton.isEnabled = false
            self.takePictureButton.isHidden = true
            self.cancelTakingPictureButton.isEnabled = false
            self.cancelTakingPictureButton.isHidden = true

            self.cropToggleButton.isEnabled = true
            self.resetCropping()
            
            self.useImageButton.isEnabled = true
            self.cancelUsingImageButton.isEnabled = true
        })

        makeResultImageViewFirstResponder()
    }

    func abort(error: Error) {

        result = .error(error)
        closeSheet()
    }

    @IBAction override func cancelOperation(_ sender: Any?) {

        result = .cancel
        closeSheet()
    }


    // MARK: Editing

    var isCropping: Bool = false {
        didSet {
            cropToggleButton.state = isCropping ? NSOnState : NSOffState
            aspectRatioCheckBox.isEnabled = isCropping
            applyCropButton.isEnabled = isCropping
            useImageButton.isEnabled = !isCropping
            cropControlsView.isHidden = !isCropping

            switch isCropping {
            case true:
                resultImageView.startCropping()
            case false:
                resultImageView.cancelCropping()
            }
        }
    }

    @IBAction func toggleCrop(_ sender: Any?) {

        isCropping = (cropToggleButton.state == NSOnState)
        
        makeResultImageViewFirstResponder()
    }

    @IBAction func toggleAspectRatio(_ sender: Any?) {

        let lockRatio = (aspectRatioCheckBox.state == NSOnState)

        switch lockRatio {
        case true:
            resultImageView.enableAspectRatio(sender)
        case false:
            resultImageView.disableAspectRatio(sender)
        }

        makeResultImageViewFirstResponder()
    }

    fileprivate func pickImage(image: NSImage) {

        result = .picture(image)
        closeSheet()
    }

    fileprivate func replaceImage(image: NSImage) {

        result = .picture(image)
        resultImageView.image = image
        resetCropping()
        makeResultImageViewFirstResponder()
    }

    @IBAction func applyCrop(_ sender: Any?) {

        resultImageView.cropSelection(sender)
    }

    @IBAction func useImage(_ sender: Any) {
        closeSheet()
    }

    fileprivate func resetCropping() {

        isCropping = false
    }

    fileprivate func makeResultImageViewFirstResponder() {

        self.window?.makeFirstResponder(resultImageView)
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
            self.result = .error(error)
            closeSheet()
            return
        }

        webcam?.start()
        webcam?.showPreview(in: previewView)
    }

    func closeSheet(returnCode: NSModalResponse = NSModalResponseOK) {

        guard let window = self.window else { preconditionFailure("expected window outlet") }

        window.sheetParent?.endSheet(window, returnCode: returnCode)
    }
}
