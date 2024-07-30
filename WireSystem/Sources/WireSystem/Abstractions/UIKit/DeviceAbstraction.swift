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

// sourcery: AutoMockable
/// A protocol which allows for abstracting `UIDevice`.
public protocol DeviceAbstraction {
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }
    var orientation: UIDeviceOrientation { get }

    var type: ZMDeviceType { get }
}

@available(*, deprecated, message: "Once we drop iOS 15 support, no iPod touch will be supported.")
public enum ZMDeviceType {
    case iPhone, iPod, iPad, unspecified
}
