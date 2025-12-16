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
import UIKit
import SwiftUI

private typealias Strings = L10n.Localizable.Conversation.WireCells.ShareLink

extension ShareLinkView {
    @MainActor
    final class ViewModel: ObservableObject {

        enum PublicLinkState {
            case initial(id: String)
            case loading(id: String)
            case disabled
            case enabling
            case enabled(id: String, url: URL, expirationDate: Date?)
            case disabling(id: String, url: URL, expirationDate: Date?)
        }

        struct UseCases {
            let getLinkData: any WireCellsGetPublicLinkDataUseCaseProtocol
            let createPublicLink: WireCellsCreatePublicLinkUseCase
            let deletePublicLink: WireCellsDeletePublicLinkUseCase
            let updatePublicLinkExpiration: WireCellsUpdatePublicLinkExpirationUseCase
            let updatePublicLinkPassword: WireCellsUpdatePublicLinkPasswordUseCase
        }

        let fileItem: FilesViewItem
        let useCases: UseCases

        enum SheetNavigation: Identifiable, Hashable {
            case password
            case expiration(linkID: String)

            var id: Self { self }
        }

        // MARK: - UI State

        @Published var sheetNavigation: SheetNavigation?
        @Published private var publicLinkState: PublicLinkState

        init(fileItem: FilesViewItem, useCases: UseCases) {
            self.fileItem = fileItem
            self.useCases = useCases
            self.publicLinkState = if let linkID = fileItem.publicLinkID {
                .initial(id: linkID)
            } else {
                .disabled
            }
        }

        var isLinkToggleOn: Bool {
            switch publicLinkState {
            case .enabled, .enabling:
                return true
            case .initial, .loading, .disabled, .disabling:
                return false
            }
        }

        var isLinkToggleEnabled: Bool {
            switch publicLinkState {
            case .initial, .loading, .enabling, .disabling:
                return false
            case .enabled, .disabled:
                return true
            }
        }

        var linkID: String? {
            switch publicLinkState {
            case let .enabled(id, _, _), let .disabling(id, _, _):
                return id
            default:
                return nil
            }
        }

        var isPasswordEnabled: Bool {
            switch publicLinkState {
            case let .enabled(_, _, expirationDate), let .disabling(_, _, expirationDate):
                return false // FIXME:
            default:
                return false
            }
        }

        // MARK: - Display Helpers

        var passwordStatusText: String {
            isPasswordEnabled ? Strings.on : Strings.off
        }

        var expirationStatusText: String {
            expirationDate != nil ? Strings.on : Strings.off
        }

        var expirationDate: Date? {
            switch publicLinkState {
            case let .enabled(_, _, expirationDate), let .disabling(_, _, expirationDate):
                return expirationDate
            default:
                return nil
            }
        }

        func loadIfNeeded() async {
            let linkID: String
            switch publicLinkState {
            case let .initial(id):
                linkID = id
            default:
                return
            }

            do {
                publicLinkState = .loading(id: linkID)
                let linkData = try await useCases.getLinkData.invoke(linkID: linkID)
                publicLinkState = .enabled(id: linkID, url: linkData.url, expirationDate: linkData.expirationDate)
            } catch {
                publicLinkState = .initial(id: linkID)
                print("Failed to fetch link data: \(error)")
            }
        }

        func copyLink() {
            guard case let .enabled(_, url, _) = publicLinkState else { return }
            UIPasteboard.general.string = url.absoluteString
        }

        func updateExpirationDate(to newDate: Date?) async {
            guard case let .enabled(id, url, _) = publicLinkState else { return }
            do {
                let result = try await useCases.updatePublicLinkExpiration.invoke(
                    linkID: id,
                    expiration: newDate
                )
                publicLinkState = .enabled(id: id, url: result.url, expirationDate: result.expirationDate)
            } catch {
                print("Failed to update expiration date: \(error)")
            }
        }

        func makeExpirationDatePickerView(linkID: String) -> some View {
            ExpirationDatePickerView(
                viewModel: ExpirationDatePickerView.ViewModel(
                    linkID: linkID,
                    expirationDate: self.expirationDate,
                    isPasswordEnabled: self.isPasswordEnabled,
                    didSave: { [weak self] newExpirationDate in
                        guard let self, case let .enabled(id, url, _) = publicLinkState else { return }

                        publicLinkState = .enabled(id: id, url: url, expirationDate: newExpirationDate)
                        sheetNavigation = nil
                    },
                    updatePublicLinkExpiration: self.useCases.updatePublicLinkExpiration
                )
            )
        }

        // MARK: - Private

        func togglePublicLink(isEnabled: Bool) async {
            switch publicLinkState {
            case .enabling, .disabling, .initial, .loading:
                assertionFailure("Should not be possible to toggle")
            case .disabled:
                publicLinkState = .enabling
                do {
                    let result = try await useCases.createPublicLink.invoke(
                        nodeID: fileItem.id,
                        fileName: fileItem.name
                    )
                    publicLinkState = .enabled(id: result.linkID, url: result.url, expirationDate: result.expirationDate)
                } catch {
                    publicLinkState = .disabled
                }
            case let .enabled(id, url, expirationDate):
                publicLinkState = .disabling(id: id, url: url, expirationDate: expirationDate)
                do {
                    try await useCases.deletePublicLink.invoke(linkID: id)
                    publicLinkState = .disabled
                } catch {
                    publicLinkState = .enabled(id: id, url: url, expirationDate: expirationDate)
                }
            }
        }
    }
}
