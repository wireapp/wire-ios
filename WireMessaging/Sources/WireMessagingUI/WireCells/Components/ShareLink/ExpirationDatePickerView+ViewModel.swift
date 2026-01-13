//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireMessagingDomain

extension ExpirationDatePickerView {

    @MainActor
    final class ViewModel: ObservableObject {
        let currentExpirationDate: Date?
        let defaultExpirationDate: Date

        private let linkID: String
        private let didSave: (Date?) -> Void
        private let updatePublicLinkExpiration: WireCellsUpdatePublicLinkExpirationUseCase

        @Published var expirationDate: Date?
        @Published var isExpirationEnabled: Bool
        @Published var isSaving = false
        @Published var isPresentingExpirationDateError = false

        init(
            linkID: String,
            calendar: Calendar = Calendar.autoupdatingCurrent,
            expirationDate: Date?,
            didSave: @escaping (Date?) -> Void,
            updatePublicLinkExpiration: WireCellsUpdatePublicLinkExpirationUseCase
        ) {
            self.defaultExpirationDate = calendar.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                .addingTimeInterval(3600)
            self.currentExpirationDate = expirationDate
            // do not assign a default here; keep nil if none provided
            self.expirationDate = expirationDate
            self.linkID = linkID
            self.isExpirationEnabled = expirationDate != nil
            self.didSave = didSave
            self.updatePublicLinkExpiration = updatePublicLinkExpiration
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
            guard hasChanges else { return false }

            // If an expiration date is set, it must be in the future
            if let date = expirationDate {
                return date > Date()
            }

            // If expirationDate is nil (i.e. disabling expiration), allow save
            return true
        }

        func save() async {
            isSaving = true
            do {
                _ = try await updatePublicLinkExpiration.invoke(
                    linkID: linkID,
                    expiration: expirationDate
                )
                didSave(expirationDate)
            } catch {
                isPresentingExpirationDateError = true
            }
            isSaving = false
        }
    }
}
