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
import WireDataModel
import WireSyncEngine

/**
 * An object that receives notifications from a profile details content controller.
 */

protocol ProfileDetailsContentControllerDelegate: AnyObject {
    /// Called when the profile details change.
    func profileDetailsContentDidChange()

    /// Called when the group role change.
    func profileGroupRoleDidChange(isAdminRole: Bool)
}

/**
 * An object that controls the content to display in the user details screen.
 */

final class ProfileDetailsContentController: NSObject,
    UITableViewDataSource,
    UITableViewDelegate,
    UserObserving {
    /**
     * The type of content that can be displayed in the profile details.
     */

    enum Content: Equatable {
        /// Display rich profile data from SCIM.
        case richProfile([UserRichProfileField])

        /// Display the status of read receipts for a 1:1 conversation.
        case readReceiptsStatus(enabled: Bool)

        /// Display the status of groud admin enabled for a group conversation.
        case groupAdminStatus(enabled: Bool)

        /// Display the reason for the forced user block.
        case blockingReason

        /// Display the message protocol used for a 1:1 conversation
        case messageProtocol(MessageProtocol)
    }

    /// The user to display the details of.
    let user: UserType

    /// The user that will see the details.
    let viewer: UserType

    /// The conversation where the profile details will be displayed.
    let conversation: ZMConversation?

    /// The current group admin status for UI.
    private var isAdminState: Bool

    // MARK: - Accessing the Content

    /// The contents to display for the current configuration.
    private(set) var contents: [Content] = []

    /// The object that will receive notifications in case of content change.
    weak var delegate: ProfileDetailsContentControllerDelegate?

    // MARK: - Properties

    private var observerToken: Any?
    private let userPropertyCellID = "UserPropertyCell"
    private let messageProtocolCellID = "MessageProtocolCell"

    // MARK: - Initialization

    /**
     * Creates the controller to display the profile details for the specified user,
     * in the scope of the given conversation.
     * - parameter user: The user to display the details of.
     * - parameter viewer: The user that will see the details. Most commonly, the self user.
     * - parameter conversation: The conversation where the profile details will be displayed.
     */

    init(user: UserType,
         viewer: UserType,
         conversation: ZMConversation?) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation

        isAdminState = conversation.map(user.isGroupAdmin) ?? false

        super.init()
        configureObservers()
        updateContent()
        ZMUserSession.shared()?.perform {
            user.refreshRichProfile()
        }
    }

    // MARK: - Calculating the Content

    /// Whether the viewer can access the rich profile data of the displayed user.
    private var viewerCanAccessRichProfile: Bool {
        return viewer.canAccessCompanyInformation(of: user)
    }

    /// Starts observing changes in the user profile.
    private func configureObservers() {
        if let userSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }
    }

    private var richProfileInfoWithEmailAndDomain: ProfileDetailsContentController.Content? {
        var richProfile = user.richProfile

        // If viewer can't access rich profile information,
        // delete all rich profile info just for displaying purposes.
        if !viewerCanAccessRichProfile, !richProfile.isEmpty {
            richProfile.removeAll()
        }

        if let email = user.emailAddress {
            richProfile.insert(UserRichProfileField(type: L10n.Localizable.Email.placeholder, value: email), at: 0)
        }
        if let domain = user.domain {
            richProfile.append(UserRichProfileField(type: L10n.Localizable.Self.Settings.AccountSection.Domain.title, value: domain))
        }

        return richProfile.isEmpty ? nil : .richProfile(richProfile)
    }

    /// Updates the content for the current configuration.
    private func updateContent() {
        switch conversation?.conversationType ?? .group {
        case .group:
            let groupAdminEnabled = conversation.map(user.isGroupAdmin) ?? false

            // Do not show group admin toggle for self user or requesting connection user
            var items: [ProfileDetailsContentController.Content] = []

            if let conversation {
                let viewerCanChangeOtherRoles = viewer.canModifyOtherMember(in: conversation)
                let userCanHaveRoleChanged = !user.isWirelessUser && !user.isFederated

                if viewerCanChangeOtherRoles, userCanHaveRoleChanged {
                    items.append(.groupAdminStatus(enabled: groupAdminEnabled))
                }
            }

            if let richProfile = richProfileInfoWithEmailAndDomain {
                // If there is rich profile data and the user is allowed to see it, display it.
                items.append(richProfile)
            }

            if user.isBlocked, user.blockState == .blockedMissingLegalholdConsent {
                items.append(.blockingReason)
            }

            contents = items

        case .oneOnOne:
            let readReceiptsEnabled = viewer.readReceiptsEnabled
            if let richProfile = richProfileInfoWithEmailAndDomain {
                // If there is rich profile data and the user is allowed to see it, display it and the read receipts status.
                contents = [richProfile, .readReceiptsStatus(enabled: readReceiptsEnabled)]
            } else {
                // If there is no rich profile data, show the read receipts.
                contents = [.readReceiptsStatus(enabled: readReceiptsEnabled)]
            }

            if let conversation, Bundle.developerModeEnabled, !ProcessInfo.processInfo.isRunningTests {
                contents.append(.messageProtocol(conversation.messageProtocol))
            }

        default:
            contents = []
        }

        delegate?.profileDetailsContentDidChange()
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.readReceiptsEnabledChanged || changeInfo.richProfileChanged else { return }
        updateContent()
    }

    // MARK: - Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        return contents.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch contents[section] {
        case let .richProfile(fields):
            return fields.count
        case .readReceiptsStatus:
            return 0
        case .groupAdminStatus:
            return 1
        case .blockingReason:
            return 1
        case .messageProtocol:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SectionTableHeader()

        switch contents[section] {
        case .groupAdminStatus:
            header.titleLabel.text = nil
            header.accessibilityIdentifier = nil
        case .richProfile:
            header.titleLabel.text = L10n.Localizable.Profile.ExtendedMetadata.header.uppercased()
            header.accessibilityIdentifier = "InformationHeader"
        case let .readReceiptsStatus(enabled):
            header.accessibilityIdentifier = "ReadReceiptsStatusHeader"
            if enabled {
                header.titleLabel.text = L10n.Localizable.Profile.ReadReceiptsEnabledMemo.header.uppercased()
            } else {
                header.titleLabel.text = L10n.Localizable.Profile.ReadReceiptsDisabledMemo.header.uppercased()
            }
        case .blockingReason:
            header.titleLabel.text = nil
            header.accessibilityIdentifier = nil
        case .messageProtocol:
            header.titleLabel.text = nil
            header.accessibilityIdentifier = nil
        }

        return header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch contents[indexPath.section] {
        case let .groupAdminStatus(groupAdminEnabled):
            let cell = tableView.dequeueReusableCell(withIdentifier: IconToggleSubtitleCell.zm_reuseIdentifier, for: indexPath) as! IconToggleSubtitleCell

            cell.configure(with: CellConfiguration.groupAdminToogle(get: {
                return groupAdminEnabled
            }, set: {_, _ in
                self.isAdminState.toggle()
                self.delegate?.profileGroupRoleDidChange(isAdminRole: self.isAdminState)
                self.updateConversationRole()
            }))

            return cell

        case let .richProfile(fields):
            let field = fields[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: userPropertyCellID) as? UserPropertyCell ?? UserPropertyCell(style: .default, reuseIdentifier: userPropertyCellID)
            cell.propertyName = field.type
            cell.propertyValue = field.value
            return cell

        case .readReceiptsStatus:
            fatalError("We do not create cells for the readReceiptsStatus section.")

        case .blockingReason:
            let cell = tableView.dequeueReusableCell(withIdentifier: UserBlockingReasonCell.zm_reuseIdentifier, for: indexPath) as! UserBlockingReasonCell
            return cell

        case let .messageProtocol(messageProtocol):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: messageProtocolCellID
            ) as? UserPropertyCell ?? UserPropertyCell(
                style: .default,
                reuseIdentifier: messageProtocolCellID
            )
            cell.propertyName = "Message protocol"
            cell.propertyValue = messageProtocol.rawValue
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch contents[section] {
        case .richProfile:
            return nil
        case .readReceiptsStatus:
            let footer = SectionTableFooter()
            footer.titleLabel.text = L10n.Localizable.Profile.ReadReceiptsMemo.body
            footer.accessibilityIdentifier = "ReadReceiptsStatusFooter"
            return footer
        case .groupAdminStatus:
            let footer = SectionTableFooter()
            footer.titleLabel.text = L10n.Localizable.Profile.GroupAdminStatusMemo.body
            footer.accessibilityIdentifier = "GroupAdminStatusFooter"
            return footer
        case .blockingReason:
            return nil
        case .messageProtocol:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func updateConversationRole() {
        let groupRoles = self.conversation?.getRoles()
        let newParticipantRole = groupRoles?.first {
            $0.name == (self.isAdminState ? ZMConversation.defaultAdminRoleName : ZMConversation.defaultMemberRoleName)
        }

        guard
            let role = newParticipantRole,
            let user = (user as? ZMUser) ?? (user as? ZMSearchUser)?.user
        else {
            return
        }

        conversation?.updateRole(of: user, to: role) { result in
            if case .failure = result {
                self.isAdminState.toggle()
                self.updateUI()
            }
        }
    }

    private func updateUI() {
        self.delegate?.profileGroupRoleDidChange(isAdminRole: self.isAdminState)
        self.delegate?.profileDetailsContentDidChange()
    }
}
