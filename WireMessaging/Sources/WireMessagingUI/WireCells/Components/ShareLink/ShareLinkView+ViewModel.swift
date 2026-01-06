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
import Foundation
import SwiftUI
import UIKit
import WireDesign
import WireFoundation
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells.ShareLink

extension ShareLinkView {
    @MainActor
    final class ViewModel: ObservableObject {

        enum PublicLinkState {
            case initial(id: String)
            case loading(creatingLink: Bool)
            case disabled
            case enabled(id: String, url: URL, expirationDate: Date?, requiresPassword: Bool)
        }

        struct UseCases {
            let getLinkData: any WireCellsGetPublicLinkDataUseCaseProtocol
            let createPublicLink: WireCellsCreatePublicLinkUseCase
            let deletePublicLink: WireCellsDeletePublicLinkUseCase
            let updatePublicLinkExpiration: WireCellsUpdatePublicLinkExpirationUseCase
            let updatePublicLinkPassword: WireCellsUpdatePublicLinkPasswordUseCase
            let getPublicLinkPasswordUseCase: WireCellsGetPublicLinkPasswordUseCase
            let storePublicLinkPasswordUseCase: WireCellsStorePublicLinkPasswordUseCase
            let deletePublicLinkPasswordUseCase: WireCellsDeletePublicLinkPasswordUseCase
        }

        typealias DateFormattingContext = (
            locale: Locale,
            calendar: Calendar,
            timeZone: TimeZone
        )

        let context: DateFormattingContext

        let fileItem: FilesViewItem
        let useCases: UseCases
        var password: String?

        enum SheetNavigation: Identifiable {
            case password(view: ShareLinkPasswordView)
            case expiration(linkID: String)

            var id: String {
                switch self {
                case let .password(view):
                    "shareLinkPasswordView\(view.id)"
                case let .expiration(linkID: linkID):
                    linkID
                }
            }
        }

        // MARK: - UI State

        @Published var sheetNavigation: SheetNavigation?
        @Published var publicLinkState: PublicLinkState
        @Published var isPresentingError = false

        init(
            fileItem: FilesViewItem,
            context: DateFormattingContext = (
                Locale.autoupdatingCurrent,
                Calendar.autoupdatingCurrent,
                TimeZone.autoupdatingCurrent
            ),
            useCases: UseCases,
        ) {
            self.fileItem = fileItem
            self.context = context
            self.useCases = useCases
            self.publicLinkState = if let linkID = fileItem.publicLinkID {
                .initial(id: linkID)
            } else {
                .disabled
            }
        }

        var isLoading: Bool {
            switch publicLinkState {
            case .loading:
                true
            default:
                false
            }
        }

        var isCreatingLink: Bool {
            switch publicLinkState {
            case let .loading(isCreatingLink) where isCreatingLink:
                true
            default:
                false
            }
        }

        var isLinkToggleOn: Bool {
            switch publicLinkState {
            case .enabled:
                true
            case .initial, .loading, .disabled:
                false
            }
        }

        var isLinkToggleEnabled: Bool {
            switch publicLinkState {
            case .initial, .loading:
                false
            case .enabled, .disabled:
                true
            }
        }

        var linkID: String? {
            switch publicLinkState {
            case let .enabled(id, _, _, _):
                id
            default:
                nil
            }
        }

        var isPasswordEnabled: Bool {
            switch publicLinkState {
            case let .enabled(_, _, _, requiresPassword):
                requiresPassword
            default:
                false
            }
        }

        // MARK: - Display Helpers

        var passwordStatusText: String {
            isPasswordEnabled ? Strings.on : Strings.off
        }

        var expirationStatusText: String {
            if let expirationDate {
                expirationDate > .now ? Strings.on : Strings.expired
            } else {
                Strings.off
            }
        }

        var expirationStatusColor: Color {
            if let expirationDate, expirationDate < .now {
                return ColorTheme.Base.error.color
            }

            return ColorTheme.Base.secondaryText.color
        }

        var expirationDescription: String {
            if let expirationDate {
                expirationDate > .now ? Strings.LinkSection.expirationDescription : Strings
                    .linkExpiredOn(formattedExpirationDate(expirationDate))
            } else {
                Strings.LinkSection.expirationDescription
            }
        }

        private func formattedExpirationDate(_ date: Date) -> String {
            let style = Date.FormatStyle(
                locale: context.locale,
                calendar: context.calendar,
                timeZone: context.timeZone
            )
            .month(.wide)
            .day()
            .year()
            .hour(.defaultDigits(amPM: .abbreviated))
            .minute()

            return date.formatted(style)
        }

        var expirationDate: Date? {
            switch publicLinkState {
            case let .enabled(_, _, expirationDate, _):
                expirationDate
            default:
                nil
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
                publicLinkState = .loading(creatingLink: false)
                password = await useCases.getPublicLinkPasswordUseCase.invoke(linkID: linkID)
                let linkData = try await useCases.getLinkData.invoke(linkID: linkID)
                publicLinkState = .enabled(
                    id: linkID,
                    url: linkData.url,
                    expirationDate: linkData.expirationDate,
                    requiresPassword: linkData.requiresPassword
                )
            } catch {
                publicLinkState = .initial(id: linkID)
                isPresentingError = true
            }
        }

        func copyLink() -> URL? {
            guard case let .enabled(_, url, _, _) = publicLinkState else { return nil }
            return url
        }

        func copyPassword() -> String? {
            guard case .enabled = publicLinkState,
                  let password else { return nil }
            return password
        }

        func makeExpirationDatePickerView(linkID: String) -> some View {
            let expDate = expirationDate
            let updatePublicLinkExpiration = useCases.updatePublicLinkExpiration

            return ExpirationDatePickerView(
                viewModel: ExpirationDatePickerView.ViewModel(
                    linkID: linkID,
                    expirationDate: expDate,
                    didSave: { [weak self] newExpirationDate in
                        guard let self,
                              case let .enabled(id, url, _, requiresPassword) = publicLinkState else { return }

                        publicLinkState = .enabled(
                            id: id,
                            url: url,
                            expirationDate: newExpirationDate,
                            requiresPassword: requiresPassword
                        )
                        sheetNavigation = nil
                    },
                    updatePublicLinkExpiration: updatePublicLinkExpiration
                )
            )
        }

        // MARK: - Private

        func togglePublicLink(isEnabled: Bool) async {
            switch publicLinkState {
            case .initial, .loading:
                assertionFailure("Should not be possible to toggle")
            case .disabled:
                publicLinkState = .loading(creatingLink: true)
                do {
                    let result = try await useCases.createPublicLink.invoke(
                        nodeID: fileItem.id,
                        fileName: fileItem.name
                    )
                    publicLinkState = .enabled(
                        id: result.linkID,
                        url: result.url,
                        expirationDate: result.expirationDate,
                        requiresPassword: result.requiresPassword
                    )
                } catch {
                    publicLinkState = .disabled
                }
            case let .enabled(id, url, expirationDate, requiresPassword):
                publicLinkState = .loading(creatingLink: false)

                do {
                    try await useCases.deletePublicLink.invoke(linkID: id)
                    if requiresPassword { await useCases.deletePublicLinkPasswordUseCase.invoke(linkID: id) }
                    password = nil
                    publicLinkState = .disabled
                } catch {
                    publicLinkState = .enabled(
                        id: id,
                        url: url,
                        expirationDate: expirationDate,
                        requiresPassword: requiresPassword
                    )
                }
            }
        }

        func makeShareLinkPasswordView() async -> ShareLinkPasswordView {
            let viewModel = ShareLinkPasswordView.ViewModel(
                password: password,
                requiresPassword: isPasswordEnabled,
                linkID: linkID,
                useCases: .init(
                    updatePublicLinkPassword: useCases.updatePublicLinkPassword,
                    storePublicLinkPasswordUseCase: useCases.storePublicLinkPasswordUseCase,
                    deletePublicLinkPasswordUseCase: useCases.deletePublicLinkPasswordUseCase
                ),
                didSave: { [weak self] requiresPassword, newPassword in
                    guard let self,
                          case let .enabled(id, url, expirationDate, _) = publicLinkState else { return }

                    password = newPassword

                    publicLinkState = .enabled(
                        id: id,
                        url: url,
                        expirationDate: expirationDate,
                        requiresPassword: requiresPassword
                    )
                    sheetNavigation = nil
                },
            )

            return ShareLinkPasswordView(viewModel: viewModel)
        }
    }
}
