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

// MARK: - OrientationDelta

/// Represents the orientation delta between the interface orientation (as a reference) and the device orientation
enum OrientationDelta: Int, CaseIterable {
    case equal
    case rotatedLeft
    case upsideDown
    case rotatedRight

    static func + (lhs: OrientationDelta, rhs: OrientationDelta) -> OrientationDelta? {
        let value = (lhs.rawValue + rhs.rawValue) % OrientationDelta.allCases.count
        return OrientationDelta(rawValue: value)
    }

    init(
        interfaceOrientation: UIInterfaceOrientation = UIWindow.interfaceOrientation ?? .unknown,
        deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
    ) {
        guard let delta = deviceOrientation.deltaFromPortrait + interfaceOrientation.deltaFromPortrait else {
            self = .equal
            return
        }
        self = delta
    }

    var radians: CGFloat {
        switch self {
        case .upsideDown:
            OrientationAngle.straight.radians
        case .rotatedLeft:
            OrientationAngle.right.radians
        case .rotatedRight:
            -OrientationAngle.right.radians
        default:
            OrientationAngle.none.radians
        }
    }

    var edgeInsetsShiftAmount: Int {
        switch self {
        case .rotatedLeft:
            1
        case .rotatedRight:
            -1
        case .upsideDown:
            2
        default:
            0
        }
    }
}

// MARK: - OrientationAngle

enum OrientationAngle {
    case none // 0°
    case right // 90°
    case straight // 180°

    var radians: CGFloat {
        switch self {
        case .none:
            0
        case .right:
            .pi / 2
        case .straight:
            .pi
        }
    }
}

extension UIDeviceOrientation {
    fileprivate var deltaFromPortrait: OrientationDelta {
        switch self {
        case .landscapeLeft:
            .rotatedLeft
        case .landscapeRight:
            .rotatedRight
        case .portraitUpsideDown:
            .upsideDown
        default:
            .equal
        }
    }
}

extension UIInterfaceOrientation {
    fileprivate var deltaFromPortrait: OrientationDelta {
        switch self {
        case .landscapeLeft:
            .rotatedLeft
        case .landscapeRight:
            .rotatedRight
        case .portraitUpsideDown:
            .upsideDown
        default:
            .equal
        }
    }
}
