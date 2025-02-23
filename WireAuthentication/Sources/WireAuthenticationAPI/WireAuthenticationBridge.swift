//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A object that facilitates intermodule communication, both **inbound**
/// (from outside into this module) and **outbound** (from inside this module
/// to the external world).

public struct WireAuthenticationBridge {

    private let onFlowCompletion: () -> Void
    private let onSuccessSSOFlowCompletion: (UUID, Data) -> Void
    private let onFailureSSOFlowCompletion: () -> Void

    public init(
        onFlowCompletion: @escaping () -> Void,
        onSuccessSSOFlowCompletion: @escaping (UUID, Data) -> Void,
        onFailureSSOFlowCompletion: @escaping () -> Void
    ) {
        self.onFlowCompletion = onFlowCompletion
        self.onSuccessSSOFlowCompletion = onSuccessSSOFlowCompletion
        self.onFailureSSOFlowCompletion = onFailureSSOFlowCompletion

    }

    public func completeFlow() {
        onFlowCompletion()
    }

    @MainActor
    public func completeSSOSuccess(userID: UUID, cookieData: Data) {
        onSuccessSSOFlowCompletion(userID, cookieData)
    }

    public func completeSSOFailure() {
        onFailureSSOFlowCompletion()
    }

}
