//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import UIKit
import QuartzCore


public enum EditingMode {
    case draw
    case edit
}

protocol Renderable : class {
    
    var bounds : CGRect { get }
    
    func draw(context : CGContext)
    
}

protocol Editable : Renderable {
    
    var selected : Bool { get set }
    var selectable : Bool { get }
    var transform : CGAffineTransform { get }
    var size : CGSize  { get }
    var scale : CGFloat { get set }
    var position : CGPoint { get set }
    var rotation : CGFloat { get set }
    
}

struct Orientation {
    
    var scale : CGFloat
    var position : CGPoint
    var rotation : CGFloat
    
    static var standard : Orientation {
        get {
            return Orientation(scale: 1, position: CGPoint.zero, rotation: 0)
        }
    }
}

public protocol CanvasDelegate {
    
    func canvasDidChange(_ canvas : Canvas)
    
}

public class Canvas: UIView {
    
    fileprivate let minimumScale : CGFloat = 0.5
    fileprivate let maximumScale : CGFloat = 3.0
    
    public var delegate : CanvasDelegate? = nil
    
    /// Defines the apperance of the brush strokes when drawing
    public var brush = Brush(size: 2, color: .black)
    
    /// Active mode of the canvas. See `EditingMode` for possible values.
    public var mode : EditingMode = .draw {
        didSet {
            selection = nil
            gestureRecognizers?.forEach({ $0.isEnabled = mode == .edit })
            setNeedsDisplay()
        }
    }
    
    /// An image on which you can draw on top.
    public var referenceImage : UIImage? {
        
        didSet {
            if let referenceImage = referenceImage, let cgImage = referenceImage.cgImage {
                let retinaImage = UIImage(cgImage: cgImage, scale: 2, orientation: referenceImage.imageOrientation)
                let image = Image(image: retinaImage, at: CGPoint.zero)
                image.sizeToFit(inRect: bounds)
                image.selectable = false
                scene = [image]
                referenceObject = image
                delegate?.canvasDidChange(self)
                setNeedsDisplay()
            }
        }
    }
    
    /// hasChanges is true if the canvas has changes which can be un done. See undo()
    public var hasChanges : Bool {
        return sceneExcludingReferenceObject.count > 0
    }
    
    private var scene : [Renderable] = []
    private var bufferImage : UIImage?
    private var stroke : Stroke?
    private var referenceObject : Image?
    private var flattenIndex : Int = 0
    
    fileprivate var sceneExcludingReferenceObject : [Renderable] {
        return scene.filter({ $0 !== referenceObject })
    }
    
    fileprivate var selection : Editable? {
        didSet {
            oldValue?.selected = false
            selection?.selected = true
        }
    }
    fileprivate var initialOrienation : Orientation = Orientation.standard
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        configureGestureRecognizers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureGestureRecognizers()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if let referenceObject = referenceObject {
            referenceObject.sizeToFit(inRect: bounds)
        }
    }
    
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if let bufferImage = bufferImage {
            bufferImage.draw(at: CGPoint.zero)
        }
        
        for renderable in scene {
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
    
    func insert(brush: Brush, at position: CGPoint) -> Stroke {
        let stroke = Stroke(at: position, brush: brush)
        scene.append(stroke)
        delegate?.canvasDidChange(self)
        return stroke
    }
    
    public func undo() {
        guard !sceneExcludingReferenceObject.isEmpty else { return }
        
        if flattenIndex == scene.count {
            bufferImage = nil
            flattenIndex = 0
        } 
        
        scene.removeLast()
        setNeedsDisplay()
        delegate?.canvasDidChange(self)
    }
    
    @discardableResult fileprivate func selectObject(at position: CGPoint) -> Editable? {
        let previousSelection = selection
        
        selection = pickObject(at: position)
        
        setNeedsDisplay()
        
        guard let newSelection = selection, selection !== previousSelection else {
            return selection
        }
        
        // move object to top
        if let index = scene.index(where: { $0 === newSelection }) {
            scene.remove(at: index)
            scene.append(newSelection)
            flattenIndex = 0
            bufferImage = nil
        }
        
        return selection
    }
    
    private func pickObject(at position: CGPoint) -> Editable? {
        let editables = scene.flatMap({ $0 as? Editable })
        return editables.reversed().first(where: { $0.selectable && $0.bounds.contains(position) })
    }
    
    private func flatten() {
        let renderables = scene.suffix(from: flattenIndex)
        
        guard renderables.count > 0 else { return }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        bufferImage?.draw(at: CGPoint.zero)
        
        if let context = UIGraphicsGetCurrentContext() {
            for renderable in renderables {
                renderable.draw(context: context)
            }
        }
        
        bufferImage =  UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        flattenIndex = scene.count
    }
    
    private var drawBounds : CGRect {
        get {
            var bounds = scene.first?.bounds ?? CGRect.zero
            
            for renderable in scene.suffix(from: 1) {
                bounds = bounds.union(renderable.bounds)
            }
            
            return bounds
        }
    }
    
    /// Return an image of the canvas content.
    public var trimmedImage : UIImage? {
        get{
            let scaleFactor : CGFloat = 2.0 // We want to render with 2x scale factor also on non-retina devices
            var image : UIImage? = nil
            selection?.selected = false
            defer {
                selection?.selected = true
            }
            
            if let referenceObject = referenceObject {

                let drawBounds = self.bounds.intersection(self.drawBounds)
                let renderScale = 1 / referenceObject.scale // We want to match resolution of the image we are drawing upon on
                let renderSize = drawBounds.size.applying(CGAffineTransform(scaleX: renderScale * scaleFactor, y: renderScale * scaleFactor))
                let renderBounds = CGRect(origin: CGPoint.zero, size: renderSize).integral.applying(CGAffineTransform(scaleX: 1 / scaleFactor, y: 1 / scaleFactor))
                
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
                
                image =  UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            } else {
                let drawBounds = self.bounds.intersection(self.drawBounds).integral
 
                UIGraphicsBeginImageContextWithOptions(drawBounds.size, true, scaleFactor)
                
                if let context = UIGraphicsGetCurrentContext() {
                    context.translateBy(x: -drawBounds.origin.x, y: -drawBounds.origin.y)
                    
                    UIColor.white.setFill()
                    context.fill(drawBounds)
                    
                    for renderable in scene {
                        renderable.draw(context: context)
                    }
                }
                
                image =  UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
            
            return image
        }
    }
    
    // MARK - Touch handling
    
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
        
        if let location = touches.first?.location(in: self), let stroke = stroke {
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

}

extension Canvas : UIGestureRecognizerDelegate {
    
    func configureGestureRecognizers() {
        let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGestureReconizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        addGestureRecognizer(panGestureRecognizer)
        
        let pinchGestureRecognizer =  UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        addGestureRecognizer(pinchGestureRecognizer)
        pinchGestureRecognizer.delegate = self
        
        let rotateGestureRecognzier = UIRotationGestureRecognizer(target: self, action: #selector(handleRotateGesture))
        rotateGestureRecognzier.delegate = self
        addGestureRecognizer(rotateGestureRecognzier)
        
        gestureRecognizers?.forEach({ $0.isEnabled = mode == .edit })
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func handleTapGesture(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .began && selection == nil {
            selectObject(at: gestureRecognizer.location(in: self))
        } else if gestureRecognizer.state == .recognized {
            selectObject(at: gestureRecognizer.location(in: self))
        }
    }
    
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            guard let selection = selectObject(at: gestureRecognizer.location(in: self)) else { break }
            initialOrienation.position = selection.position
        case .changed:
            guard let selection = selection else { break }
            let translation = gestureRecognizer.translation(in: self)
            selection.position = CGPoint(x: initialOrienation.position.x + translation.x, y: initialOrienation.position.y + translation.y)
            setNeedsDisplay()
        default:
            break
        }
        
    }
    
    func handlePinchGesture(gestureRecognizer: UIPinchGestureRecognizer) {
        if let selection = selection {
            
            switch gestureRecognizer.state {
            case .began:
                initialOrienation.scale = selection.scale
            case .changed:
                selection.scale = min(max(initialOrienation.scale * gestureRecognizer.scale, minimumScale), maximumScale)
                setNeedsDisplay()
            default:
                break
            }
            
        }
    }
    
    func handleRotateGesture(gestureRecognizer: UIRotationGestureRecognizer) {
        if let selection = selection {
            
            switch gestureRecognizer.state {
            case .began:
                initialOrienation.rotation = selection.rotation
            case .changed:
                selection.rotation = initialOrienation.rotation + gestureRecognizer.rotation
                setNeedsDisplay()
            default:
                break
            }
            
        }
    }
    
}
