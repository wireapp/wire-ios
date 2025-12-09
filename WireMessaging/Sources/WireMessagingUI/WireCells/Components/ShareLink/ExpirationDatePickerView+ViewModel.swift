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
import SwiftUI

extension ExpirationDatePickerView {
    @MainActor
    final class ViewModel: ObservableObject {
        let currentExpirationDate: Date?
        let defaultExpirationDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            .addingTimeInterval(3600)

        @Published var expirationDate: Date?
        @Published var isExpirationEnabled: Bool

        init(expirationDate: Date?) {
            self.currentExpirationDate = expirationDate
            // do not assign a default here; keep nil if none provided
            self.expirationDate = expirationDate
            self.isExpirationEnabled = expirationDate != nil
        }

        func enableExpirationDate() {
            if currentExpirationDate == nil {
                expirationDate = defaultExpirationDate
            }
            isExpirationEnabled = true
        }

        func disableExpirationDate() {
            expirationDate = nil
            isExpirationEnabled = false
        }

        var hasChanges: Bool {
            expirationDate != currentExpirationDate
        }

        var canSave: Bool {
            hasChanges
        }
    }
}
