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
import XCTest
@testable import Wire

final class MockPhotoPermissionsController: PhotoPermissionsController {
    // MARK: Lifecycle

    init(camera: Bool, library: Bool) {
        self.camera = camera
        self.library = library
    }

    // MARK: Internal

    var isCameraAuthorized: Bool {
        camera
    }

    var isPhotoLibraryAuthorized: Bool {
        library
    }

    var areCameraOrPhotoLibraryAuthorized: Bool {
        camera || library
    }

    var areCameraAndPhotoLibraryAuthorized: Bool {
        camera && library
    }

    // MARK: Private

    private var camera = false
    private var library = false
}
