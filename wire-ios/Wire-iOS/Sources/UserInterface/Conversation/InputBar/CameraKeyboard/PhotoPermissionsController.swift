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

import Foundation

// This protocol is used for UI (& testing) purposes only.
// In case you'll create a class compliant with this protocol, that returns `true`
// to all the variables specified, you simply won't see the "Wire needs access to..."
// messages, but only empty cells. You won't get any data until the user gives
// his permission via the iOS standard dialog.

protocol PhotoPermissionsController {
    var isCameraAuthorized: Bool { get }
    var isPhotoLibraryAuthorized: Bool { get }
    var areCameraOrPhotoLibraryAuthorized: Bool { get }
    var areCameraAndPhotoLibraryAuthorized: Bool { get }
}
