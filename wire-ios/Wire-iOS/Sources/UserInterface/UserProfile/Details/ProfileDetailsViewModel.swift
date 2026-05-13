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

import Foundation
import WireDataModel
import WireSyncEngine

final class ProfileDetailsViewModel {

    struct DisplayState: Equatable {
        let sections: [Section]
    }

    struct Section: Equatable {
        let headerTitle: String?
        let headerAccessibilityIdentifier: String?
        let footerTitle: String?
        let footerAccessibilityIdentifier: String?
        let rows: [Row]
        let content: Content
    }

    enum Row: Equatable {
        case richProfileField(title: String, value: String)
        case groupAdminStatus(enabled: Bool)
        case blockingReason
        case messageProtocol(title: String, value: String)
    }

    enum Content: Equatable {
        case richProfile([UserRichProfileField])
        case readReceiptsStatus(enabled: Bool)
        case groupAdminStatus(enabled: Bool)
        case blockingReason
        case messageProtocol(MessageProtocol)
    }

    enum Action: Equatable {
        case updateGroupAdminStatus(enabled: Bool)
    }

    private let user: UserType
    private let viewer: UserType
    private let conversation: ZMConversation?
    private let showsDeveloperMessageProtocol: Bool

    private var isAdminState: Bool

    private(set) var displayState: DisplayState

    init(
        user: UserType,
        viewer: UserType,
        conversation: ZMConversation?,
        showsDeveloperMessageProtocol: Bool = Bundle.developerModeEnabled && !ProcessInfo.processInfo.isRunningTests
    ) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation
        self.showsDeveloperMessageProtocol = showsDeveloperMessageProtocol
        self.isAdminState = conversation.map(user.isGroupAdmin) ?? false
        self.displayState = DisplayState(sections: [])

        refreshDisplayState()
    }

    func refreshDisplayState() {
        displayState = DisplayState(sections: makeContents().map(makeSection))
    }

    func setGroupAdminStatus(_ isEnabled: Bool) -> Action {
        isAdminState = isEnabled
        refreshDisplayState()
        return .updateGroupAdminStatus(enabled: isEnabled)
    }

    func revertGroupAdminStatus() {
        isAdminState.toggle()
        refreshDisplayState()
    }

    private var viewerCanAccessRichProfile: Bool {
        viewer.canAccessCompanyInformation(of: user)
    }

    private var richProfileInfoWithEmailAndDomain: Content? {
        var richProfile = user.richProfile

        if !viewerCanAccessRichProfile, !richProfile.isEmpty {
            richProfile.removeAll()
        }

        if let email = user.emailAddress {
            richProfile.insert(UserRichProfileField(type: L10n.Localizable.Email.placeholder, value: email), at: 0)
        }

        if let domain = user.domain {
            richProfile.append(UserRichProfileField(
                type: L10n.Localizable.Self.Settings.AccountSection.Domain.title,
                value: domain
            ))
        }

        return richProfile.isEmpty ? nil : .richProfile(richProfile)
    }

    private func makeContents() -> [Content] {
        switch conversation?.conversationType ?? .group {
        case .group:
            var items: [Content] = []

            if let conversation {
                let viewerCanChangeOtherRoles = viewer.canModifyOtherMember(in: conversation)
                let userCanHaveRoleChanged = !user.isWirelessUser && !user.isFederated

                if viewerCanChangeOtherRoles, userCanHaveRoleChanged {
                    items.append(.groupAdminStatus(enabled: isAdminState))
                }
            }

            if let richProfile = richProfileInfoWithEmailAndDomain {
                items.append(richProfile)
            }

            if user.isBlocked, user.blockState == .blockedMissingLegalholdConsent {
                items.append(.blockingReason)
            }

            return items

        case .oneOnOne:
            var items: [Content] = []

            if let richProfile = richProfileInfoWithEmailAndDomain {
                items.append(richProfile)
            }

            items.append(.readReceiptsStatus(enabled: viewer.readReceiptsEnabled))

            if let conversation, showsDeveloperMessageProtocol {
                items.append(.messageProtocol(conversation.messageProtocol))
            }

            return items

        default:
            return []
        }
    }

    private func makeSection(for content: Content) -> Section {
        switch content {
        case let .groupAdminStatus(enabled):
            Section(
                headerTitle: nil,
                headerAccessibilityIdentifier: nil,
                footerTitle: L10n.Localizable.Profile.GroupAdminStatusMemo.body,
                footerAccessibilityIdentifier: "GroupAdminStatusFooter",
                rows: [.groupAdminStatus(enabled: enabled)],
                content: content
            )

        case let .richProfile(fields):
            Section(
                headerTitle: L10n.Localizable.Profile.ExtendedMetadata.header.uppercased(),
                headerAccessibilityIdentifier: "InformationHeader",
                footerTitle: nil,
                footerAccessibilityIdentifier: nil,
                rows: fields.map { .richProfileField(title: $0.type, value: $0.value) },
                content: content
            )

        case let .readReceiptsStatus(enabled):
            Section(
                headerTitle: readReceiptsHeaderTitle(isEnabled: enabled),
                headerAccessibilityIdentifier: "ReadReceiptsStatusHeader",
                footerTitle: L10n.Localizable.Profile.ReadReceiptsMemo.body,
                footerAccessibilityIdentifier: "ReadReceiptsStatusFooter",
                rows: [],
                content: content
            )

        case .blockingReason:
            Section(
                headerTitle: nil,
                headerAccessibilityIdentifier: nil,
                footerTitle: nil,
                footerAccessibilityIdentifier: nil,
                rows: [.blockingReason],
                content: content
            )

        case let .messageProtocol(messageProtocol):
            Section(
                headerTitle: nil,
                headerAccessibilityIdentifier: nil,
                footerTitle: nil,
                footerAccessibilityIdentifier: nil,
                rows: [.messageProtocol(
                    title: L10n.Localizable.GroupDetails.MessageProtocol.title,
                    value: messageProtocol.rawValue
                )],
                content: content
            )
        }
    }

    private func readReceiptsHeaderTitle(isEnabled: Bool) -> String {
        if isEnabled {
            L10n.Localizable.Profile.ReadReceiptsEnabledMemo.header.uppercased()
        } else {
            L10n.Localizable.Profile.ReadReceiptsDisabledMemo.header.uppercased()
        }
    }
}
