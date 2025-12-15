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
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells.ShareLink

extension ShareLinkView {
    @MainActor
    final class ViewModel: ObservableObject {
        struct UseCases {
            let getLinkData: any WireCellsGetPublicLinkDataUseCaseProtocol
            // TODO: Add the rest of use case to create/update/delete
        }

        let fileItem: FilesViewItem
        let useCases: UseCases

        enum SheetNavigation: String, Identifiable {
            case password
            case expiration

            var id: String { rawValue }
        }

        // MARK: - UI State

        @Published var sheetNavigation: SheetNavigation?
        @Published var isLinkActive: Bool = false

        // These hold the configuration to be saved
        @Published var password: String?
        @Published var expirationDate: Date?

        init(fileItem: FilesViewItem, useCases: UseCases) {
            self.fileItem = fileItem
            self.useCases = useCases

            self.isLinkActive = fileItem.publicLinkId != nil

            if let publicLinkId = fileItem.publicLinkId {
                Task { await getLinkData(publicLinkId: publicLinkId) }
            }
        }

        private func getLinkData(publicLinkId: String) async {
            // Call to API to get existing password/date from the link data and parse it here
            guard let linkId = UUID(uuidString: publicLinkId) else { return }

            do {
                let linkData = try await useCases.getLinkData.invoke(linkId: linkId)
                password = linkData.password
                expirationDate = linkData.expirationDate
            } catch {
                print("Failed to fetch link data: \(error)")
            }
        }

        // MARK: - Display Helpers

        var passwordStatusText: String {
            password != nil ? Strings.on : Strings.off
        }

        var expirationStatusText: String {
            expirationDate != nil ? Strings.on : Strings.off
        }

        func saveLink() {
            // TODO: Implement the actual API call to create/update the link
            print(
                "Saving link: Active: \(isLinkActive), Pwd: \(String(describing: password)), Exp: \(String(describing: expirationDate))"
            )
        }
    }
}
