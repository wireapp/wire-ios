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
import WireDataModel

@objc
extension ZMOperationLoop {
    public var currentAPIVersion: APIVersionWrapper? {
        guard let current = BackendInfo.apiVersion else {
            return nil
        }
        return .init(value: current)
    }
}

// MARK: - APIVersionWrapper

/// A helper object to give reference semantics to `APIVersion`.
///
/// This is needed because the optional type`APIVersion?` can't be
/// represented in objc.

@objc
public class APIVersionWrapper: NSObject {
    // MARK: Lifecycle

    init(value: APIVersion) {
        self.value = value
        super.init()
    }

    // MARK: Public

    @objc public var value: APIVersion
}
