//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import QuartzCore
import UIKit

// MARK: - EditingMode

public enum EditingMode {
    case draw
    case edit
}

// MARK: - Renderable

protocol Renderable: AnyObject {
    var bounds: CGRect { get }

    func draw(context: CGContext)
}

// MARK: - Editable

protocol Editable: Renderable {
    var selected: Bool { get set }
    var selectedView: UIView { get }
    var selectable: Bool { get }
    var transform: CGAffineTransform { get }
    var size: CGSize { get }
    var scale: CGFloat { get set }
    var position: CGPoint { get set }
    var rotation: CGFloat { get set }
}

// MARK: - Orientation

struct Orientation {
    static var standard: Orientation {
        Orientation(scale: 1, position: CGPoint.zero, rotation: 0)
    }

    var scale: CGFloat
    var position: CGPoint
    var rotation: CGFloat
}

// MARK: - CanvasDelegate

public protocol CanvasDelegate: AnyObject {
    func canvasDidChange(_ canvas: Canvas)
}

// MARK: - Canvas

public final class Canvas: UIView {
    // MARK: Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        configureGestureRecognizers()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.drawsAsynchronously = true

        configureGestureRecognizers()
    }

    // MARK: Public

    public weak var delegate: CanvasDelegate?

    /// Defines the apperance of the brush strokes when drawing
    public var brush = Brush(size: 2, color: .black)

    /// Active mode of the canvas. See `EditingMode` for possible values.
    public var mode: EditingMode = .draw {
        didSet {
            selection = nil
            gestureRecognizers?.forEach { $0.isEnabled = mode == .edit }
            setNeedsDisplay()
        }
    }

    /// An image on which you can draw on top.
    public var referenceImage: UIImage? {
        didSet {
            if let referenceImage, let cgImage = referenceImage.cgImage {
                let retinaImage = UIImage(cgImage: cgImage, scale: 2, orientation: referenceImage.imageOrientation)
                let image = Image(image: retinaImage, at: CGPoint.zero)
                image.sizeToFit(inRect: bounds)
                image.selectable = false
                scene = [image]
                unflatten()
                referenceObject = image
                delegate?.canvasDidChange(self)
                setNeedsDisplay()
            }
        }
    }

    /// hasChanges is true if the canvas has changes which can be un done. See undo()
    public var hasChanges: Bool {
        !sceneExcludingReferenceObject.isEmpty
    }

    /// Return an image of the canvas content.
    public var trimmedImage: UIImage? {
        let scaleFactor: CGFloat = 2.0 // We want to render with 2x scale factor also on non-retina devices
        var image: UIImage?
        selection?.selected = false
        defer {
            selection?.selected = true
        }

        if let referenceObject {
            let drawBounds = bounds.intersection(drawBounds)
            let renderScale = 1 / referenceObject
                .scale // We want to match resolution of the image we are drawing upon on
            let renderSize = drawBounds.size.applying(CGAffineTransform(
                scaleX: renderScale * scaleFactor,
                y: renderScale * scaleFactor
            ))
            let renderBounds = CGRect(origin: CGPoint.zero, size: renderSize).integral.applying(CGAffineTransform(
                scaleX: 1 / scaleFactor,
                y: 1 / scaleFactor
            ))

            UIGraphicsBeginImageContextWithOptions(renderBounds.size, true, scaleFactor)

            if let context = UIGraphicsGetCurrentContext() {
                context.scaleBy(x: renderScale, y: renderScale)
                context.translateBy(x: -drawBounds.origin.x, y: -drawBounds.origin.y)

                UIColor.white.setFill()
                context.fill(CGRect(origin: drawBounds.origin, size: renderBounds.size))

                for renderable in scene {
                    renderable.draw(context: context)
                }
            }

            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        } else {
            let drawBounds = bounds.intersection(drawBounds).integral

            UIGraphicsBeginImageContextWithOptions(drawBounds.size, true, scaleFactor)

            if let context = UIGraphicsGetCurrentContext() {
                context.translateBy(x: -drawBounds.origin.x, y: -drawBounds.origin.y)

                UIColor.white.setFill()
                context.fill(drawBounds)

                for renderable in scene {
                    renderable.draw(context: context)
                }
            }

            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }

        return image
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        if let referenceObject {
            referenceObject.sizeToFit(inRect: bounds)
        }
    }

    override public func draw(_: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        if flattenIndex == 0, referenceObject != nil {
            flatten(upTo: 1)
        }

        if let bufferImage {
            bufferImage.draw(at: CGPoint.zero)
        }

        for renderable in scene.suffix(from: flattenIndex) {
            renderable.draw(context: context)
        }
    }

    public func insert(image: UIImage, at position: CGPoint) {
        let image = Image(image: image, at: position)

        scene.append(image)
        selection = image
        setNeedsDisplay()
        delegate?.canvasDidChange(self)
    }

    @objc
    public func undo() {
        guard !sceneExcludingReferenceObject.isEmpty else { return }

        if flattenIndex == scene.count {
            unflatten()
        }

        if selection === scene.removeLast() {
            selection = nil
        }

        setNeedsDisplay()
        delegate?.canvasDidChange(self)
    }

    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizers?.contains(gestureRecognizer) ?? false
    }

    // MARK: - Touch handling

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard mode == .draw else { return }

        if let location = touches.first?.location(in: self) {
            let stroke = insert(brush: brush, at: location)
            setNeedsDisplay(stroke.bounds)
            self.stroke = stroke
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard mode == .draw else { return }

        if let location = touches.first?.location(in: self), let stroke {
            setNeedsDisplay(stroke.move(to: location))
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard mode == .draw else { return }

        stroke?.end()
        flatten()
        setNeedsDisplay()
    }

    // MARK: Internal

    func insert(brush: Brush, at position: CGPoint) -> Stroke {
        let stroke = Stroke(at: position, brush: brush)
        scene.append(stroke)
        delegate?.canvasDidChange(self)
        return stroke
    }

    // MARK: Fileprivate

    fileprivate let minimumScale: CGFloat = 0.5
    fileprivate let maximumScale: CGFloat = 10.0

    fileprivate var initialOrienation = Orientation.standard

    fileprivate var sceneExcludingReferenceObject: [Renderable] {
        scene.filter { $0 !== referenceObject }
    }

    fileprivate var selection: Editable? {
        didSet {
            guard selection !== oldValue else { return }

            selectionView?.removeFromSuperview()
            selectionView = selection?.selectedView

            if let selectedView = selectionView {
                addSubview(selectedView)
            }

            oldValue?.selected = false
            selection?.selected = true

            if let oldSelection = oldValue {
                setNeedsDisplay(oldSelection.bounds)
            }

            if let newSelection = selection {
                setNeedsDisplay(newSelection.bounds)
            }
        }
    }

    @discardableResult
    fileprivate func selectObject(at position: CGPoint) -> Editable? {
        let previousSelection = selection

        selection = pickObject(at: position)

        guard let newSelection = selection, selection !== previousSelection else {
            return selection
        }

        // move object to top
        if let index = scene.firstIndex(where: { $0 === newSelection }) {
            scene.remove(at: index)
            scene.append(newSelection)
            unflatten()
        }

        return selection
    }

    // MARK: Private

    private var scene: [Renderable] = []
    private var bufferImage: UIImage?
    private var selectionView: UIView?
    private var stroke: Stroke?
    private var referenceObject: Image?
    private var flattenIndex = 0

    private var drawBounds: CGRect {
        var bounds = scene.first?.bounds ?? CGRect.zero

        for renderable in scene.suffix(from: 1) {
            bounds = bounds.union(renderable.bounds)
        }

        return bounds
    }

    private func pickObject(at position: CGPoint) -> Editable? {
        let editables = scene.compactMap { $0 as? Editable }
        return editables.reversed().first(where: { editable in
            guard editable.selectable else { return false }
            let bounds = CGRect(origin: CGPoint.zero, size: editable.size)
            let position = position.applying(editable.transform.inverted())
            return bounds.contains(position)
        })
    }

    private func unflatten() {
        flattenIndex = 0
        bufferImage = nil
    }

    private func flatten() {
        flatten(upTo: scene.count)
    }

    private func flatten(upTo: Int) {
        let renderables = scene.prefix(upTo: upTo).suffix(from: flattenIndex)

        guard !renderables.isEmpty else { return }

        selection?.selected = false
        defer {
            selection?.selected = true
        }

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        bufferImage?.draw(at: CGPoint.zero)

        if let context = UIGraphicsGetCurrentContext() {
            for renderable in renderables {
                renderable.draw(context: context)
            }
        }

        bufferImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        flattenIndex = upTo
    }
}

// MARK: UIGestureRecognizerDelegate

extension Canvas: UIGestureRecognizerDelegate {
    func configureGestureRecognizers() {
        let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGestureReconizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        addGestureRecognizer(panGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        addGestureRecognizer(pinchGestureRecognizer)
        pinchGestureRecognizer.delegate = self

        let rotateGestureRecognzier = UIRotationGestureRecognizer(target: self, action: #selector(handleRotateGesture))
        rotateGestureRecognzier.delegate = self
        addGestureRecognizer(rotateGestureRecognzier)

        gestureRecognizers?.forEach { $0.isEnabled = mode == .edit }
    }

    @objc
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    @objc
    func handleTapGesture(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .began, selection == nil {
            selectObject(at: gestureRecognizer.location(in: self))
        } else if gestureRecognizer.state == .recognized {
            selectObject(at: gestureRecognizer.location(in: self))
        }
    }

    @objc
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            guard let selection = selectObject(at: gestureRecognizer.location(in: self)) else { break }
            initialOrienation.position = selection.position

        case .changed:
            guard let selection else { break }
            let translation = gestureRecognizer.translation(in: self)
            selection.position = CGPoint(
                x: initialOrienation.position.x + translation.x,
                y: initialOrienation.position.y + translation.y
            )

        default:
            break
        }
    }

    @objc
    func handlePinchGesture(gestureRecognizer: UIPinchGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            guard let selection = selectObject(at: gestureRecognizer.location(in: self)) else { break }
            initialOrienation.scale = selection.scale

        case .changed:
            guard let selection else { break }
            selection.scale = min(max(initialOrienation.scale * gestureRecognizer.scale, minimumScale), maximumScale)

        default:
            break
        }
    }

    @objc
    func handleRotateGesture(gestureRecognizer: UIRotationGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            guard let selection = selectObject(at: gestureRecognizer.location(in: self)) else { break }
            initialOrienation.rotation = selection.rotation

        case .changed:
            guard let selection else { break }
            selection.rotation = initialOrienation.rotation + gestureRecognizer.rotation

        default:
            break
        }
    }
}
