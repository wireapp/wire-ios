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

public func ProgressIndicatorRotationAnimation(
    rotationSpeed: CFTimeInterval,
    beginTime: CFTimeInterval
) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "transform.rotation")

    animation.fillMode = .forwards

    animation.toValue = Double.pi
    animation.repeatCount = .greatestFiniteMagnitude

    animation.duration = rotationSpeed / 2
    animation.beginTime = beginTime
    animation.isCumulative = true
    animation.timingFunction = .init(name: .linear)

    return animation
}
