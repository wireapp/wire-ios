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

import UIKit

// MARK: - Brush

public struct Brush {
    // MARK: Lifecycle

    public init(size: Float, color: UIColor) {
        self.size = size
        self.color = color
    }

    // MARK: Public

    public func change(toColor color: UIColor) -> Brush {
        Brush(size: size, color: color)
    }

    public func change(toSize size: Float) -> Brush {
        Brush(size: size, color: color)
    }

    // MARK: Internal

    let size: Float
    let color: UIColor
}

// MARK: - Stroke

final class Stroke: Renderable {
    // MARK: Lifecycle

    public init(at position: CGPoint, brush: Brush) {
        self.brush = brush
        self.points = [position]
    }

    // MARK: Internal

    var bounds: CGRect {
        bounds(from: 0)
    }

    func move(to point: CGPoint) -> CGRect {
        guard distance(to: point) > minimumStrokeDistance else {
            return CGRect.zero
        }

        points.append(smooth(point: point))

        return bounds(from: max(points.count - 3, 0)) // Need to update last two segments
    }

    func end() {}

    func draw(context: CGContext) {
        if points.count == 1, let point = points.first {
            context.setFillColor(brush.color.cgColor)
            let origin = CGPoint(x: point.x - CGFloat(brush.size / 2), y: point.y - CGFloat(brush.size / 2))
            context.addEllipse(in: CGRect(
                origin: origin,
                size: CGSize(width: Double(brush.size), height: Double(brush.size))
            ))
            context.fillPath()
        } else {
            context.setStrokeColor(brush.color.cgColor)
            let path = interpolateBeizerPath(points: points)
            path.lineWidth = CGFloat(brush.size)
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    func distance(to point: CGPoint) -> Double {
        let lastPoint = points.last!
        let translation = CGPoint(x: point.x - lastPoint.x, y: point.y - lastPoint.y)
        return sqrt(Double(translation.x * translation.x + translation.y * translation.y))
    }

    func bounds(from index: Int) -> CGRect {
        var minX = Double.infinity
        var minY = Double.infinity
        var maxX = -Double.infinity
        var maxY = -Double.infinity

        for point in points.suffix(from: index) {
            minX = min(Double(point.x), minX)
            minY = min(Double(point.y), minY)
            maxX = max(Double(point.x), maxX)
            maxY = max(Double(point.y), maxY)
        }

        let outset = CGFloat(-brush.size)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).insetBy(dx: outset, dy: outset)
    }

    func smooth(point: CGPoint, factor: CGFloat = 0.35) -> CGPoint {
        let previous = points.last!
        return CGPoint(
            x: previous.x * (1 - factor) + point.x * factor,
            y: previous.y * (1 - factor) + point.y * factor
        )
    }

    func interpolateBeizerPath(points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: points.first!)
        path.lineWidth = CGFloat(brush.size)

        let controlPoints = controlsPoints(points: points)

        for i in 1 ..< points.count {
            path.addCurve(to: points[i], controlPoint1: controlPoints[i - 1].1, controlPoint2: controlPoints[i].0)
        }

        return path
    }

    func controlsPoints(points: [CGPoint]) -> [(CGPoint, CGPoint)] {
        let points = [points.first!] + points + [points.last!]
        var controlPoints: [(CGPoint, CGPoint)] = []

        for i in 1 ..< points.count - 1 {
            let p0 = points[i - 1]
            let p1 = points[i]
            let p2 = points[i + 1]

            let v0 = CGPoint(x: p1.x - p0.x, y: p1.y - p0.y)
            let v1 = CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)

            let a0 = CGPoint(x: p0.x + 0.5 * v0.x, y: p0.y + 0.5 * v0.y)
            let a1 = CGPoint(x: p1.x + 0.5 * v1.x, y: p1.y + 0.5 * v1.y)

            let len0 = v0.x * v0.x + v0.y * v0.y
            let len1 = v1.x * v1.x + v1.y * v1.y
            let ratio = len0 / (len0 + len1)

            let b0 = CGPoint(x: a0.x - a1.x, y: a0.y - a1.y)

            let d0 = CGPoint(x: b0.x * ratio, y: b0.y * ratio)
            let d1 = CGPoint(x: b0.x * (ratio - 1), y: b0.y * (ratio - 1))

            let cp0 = CGPoint(x: p1.x + d0.x, y: p1.y + d0.y)
            let cp1 = CGPoint(x: p1.x + d1.x, y: p1.y + d1.y)

            controlPoints.append((cp0, cp1))
        }

        return controlPoints
    }

    // MARK: Private

    private var points: [CGPoint]
    private let minimumStrokeDistance = 0.1
    private let brush: Brush
}
