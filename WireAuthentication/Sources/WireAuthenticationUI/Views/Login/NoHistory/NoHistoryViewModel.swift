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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI

@MainActor
package final class NoHistoryViewModel: ObservableObject {

    private let userID: UUID
    private let cookieData: Data
    private let onFlowCompletion: () -> Void

    package init(
        userID: UUID,
        cookieData: Data,
        onFlowCompletion: @escaping () -> Void
    ) {
        self.userID = userID
        self.cookieData = cookieData
        self.onFlowCompletion = onFlowCompletion
    }

    func confirm() {
        onFlowCompletion()
    }
}
