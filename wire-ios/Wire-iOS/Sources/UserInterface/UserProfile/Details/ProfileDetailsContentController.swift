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

import UIKit
import WireDataModel
import WireSyncEngine

/// An object that receives notifications from a profile details content controller.

protocol ProfileDetailsContentControllerDelegate: AnyObject {

    /// Called when the profile details change.
    func profileDetailsContentDidChange()

    /// Called when the group role change.
    func profileGroupRoleDidChange(isAdminRole: Bool)
}

/// An object that controls the content to display in the user details screen.

final class ProfileDetailsContentController: NSObject,
    UITableViewDataSource,
    UITableViewDelegate,
    UserObserving {

    /// The type of content that can be displayed in the profile details.

    typealias Content = ProfileDetailsViewModel.Content

    /// The user to display the details of.
    let user: UserType

    /// The user that will see the details.
    let viewer: UserType

    /// The conversation where the profile details will be displayed.
    let conversation: ZMConversation?

    // MARK: - Accessing the Content

    /// The contents to display for the current configuration.
    var contents: [Content] {
        viewModel.displayState.sections.map(\.content)
    }

    /// The object that will receive notifications in case of content change.
    weak var delegate: ProfileDetailsContentControllerDelegate?

    // MARK: - Properties

    private var observerToken: Any?
    private let userSession: UserSession
    private let viewModel: ProfileDetailsViewModel
    private let userPropertyCellID = "UserPropertyCell"
    private let messageProtocolCellID = "MessageProtocolCell"

    // MARK: - Initialization

    /// Creates the controller to display the profile details for the specified user,
    /// in the scope of the given conversation.
    /// - parameter user: The user to display the details of.
    /// - parameter viewer: The user that will see the details. Most commonly, the self user.
    /// - parameter conversation: The conversation where the profile details will be displayed.

    init(
        user: UserType,
        viewer: UserType,
        conversation: ZMConversation?,
        userSession: UserSession,
        viewModel: ProfileDetailsViewModel
    ) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation
        self.userSession = userSession
        self.viewModel = viewModel

        super.init()
        configureObservers()
        userSession.perform {
            user.refreshRichProfile()
        }
    }

    convenience init(
        user: UserType,
        viewer: UserType,
        conversation: ZMConversation?,
        userSession: UserSession
    ) {
        self.init(
            user: user,
            viewer: viewer,
            conversation: conversation,
            userSession: userSession,
            viewModel: ProfileDetailsViewModel(user: user, viewer: viewer, conversation: conversation)
        )
    }

    // MARK: - Calculating the Content

    /// Starts observing changes in the user profile.
    private func configureObservers() {
        if let userSession = userSession as? ZMUserSession {
            observerToken = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }
    }

    /// Updates the content for the current configuration.
    private func updateContent() {
        viewModel.refreshDisplayState()
        delegate?.profileDetailsContentDidChange()
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.readReceiptsEnabledChanged || changeInfo.richProfileChanged else { return }
        updateContent()
    }

    // MARK: - Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.displayState.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.displayState.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SectionTableHeader()
        let section = viewModel.displayState.sections[section]
        header.titleLabel.text = section.headerTitle
        header.accessibilityIdentifier = section.headerAccessibilityIdentifier

        return header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.displayState.sections[indexPath.section].rows[indexPath.row]

        switch row {
        case let .groupAdminStatus(groupAdminEnabled):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: IconToggleSubtitleCell.zm_reuseIdentifier,
                for: indexPath
            ) as! IconToggleSubtitleCell

            cell.configure(with: CellConfiguration.groupAdminToggle(get: {
                groupAdminEnabled
            }, set: { isEnabled, _ in
                let action = self.viewModel.setGroupAdminStatus(isEnabled)

                let isAdminRole: Bool
                switch action {
                case let .updateGroupAdminStatus(enabled):
                    isAdminRole = enabled
                }

                self.delegate?.profileGroupRoleDidChange(isAdminRole: isAdminRole)
                self.delegate?.profileDetailsContentDidChange()
                self.updateConversationRole(isAdminRole: isAdminRole)
            }))

            return cell

        case let .richProfileField(title, value):
            let cell = tableView
                .dequeueReusableCell(withIdentifier: userPropertyCellID) as? UserPropertyCell ?? UserPropertyCell(
                    style: .default,
                    reuseIdentifier: userPropertyCellID
                )
            cell.propertyName = title
            cell.propertyValue = value
            return cell

        case .blockingReason:
            return tableView.dequeueReusableCell(
                withIdentifier: UserBlockingReasonCell.zm_reuseIdentifier,
                for: indexPath
            ) as! UserBlockingReasonCell

        case let .messageProtocol(title, value):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: messageProtocolCellID
            ) as? UserPropertyCell ?? UserPropertyCell(
                style: .default,
                reuseIdentifier: messageProtocolCellID
            )
            cell.propertyName = title
            cell.propertyValue = value
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let section = viewModel.displayState.sections[section]
        guard section.footerTitle != nil || section.footerAccessibilityIdentifier != nil else {
            return nil
        }

        let footer = SectionTableFooter()
        footer.titleLabel.text = section.footerTitle
        footer.accessibilityIdentifier = section.footerAccessibilityIdentifier
        return footer
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func updateConversationRole(isAdminRole: Bool) {
        let groupRoles = conversation?.getRoles()
        let newParticipantRole = groupRoles?.first {
            $0.name == (isAdminRole ? ZMConversation.defaultAdminRoleName : ZMConversation.defaultMemberRoleName)
        }

        guard
            let role = newParticipantRole,
            let user = (user as? ZMUser) ?? (user as? ZMSearchUser)?.user
        else {
            return
        }

        conversation?.updateRole(of: user, to: role) { result in
            if case .failure = result {
                self.viewModel.revertGroupAdminStatus()
                self.updateUI()
            }
        }
    }

    private func updateUI() {
        guard case let .groupAdminStatus(isAdminRole) = contents.first(where: {
            if case .groupAdminStatus = $0 { return true }
            return false
        }) else {
            return
        }

        delegate?.profileGroupRoleDidChange(isAdminRole: isAdminRole)
        delegate?.profileDetailsContentDidChange()
    }
}
