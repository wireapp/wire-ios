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
import UIKit
import WireDataModel
import WireLogging
import WireSyncEngine

final class MessageProtocolSectionController: GroupDetailsSectionController {

    typealias Cell = DetailsCollectionViewCell

    // MARK: - Properties

    let conversation: ZMConversation?
    private let messageProtocol: MessageProtocol
    private let ciphersuite: MLSCipherSuite?
    private let groupID: MLSGroupID?
    private let userSession: UserSession
    weak var presentingViewController: UIViewController?

    /// Timestamps of the most recent taps on the protocol row, used to detect the
    /// 5-taps-in-5-seconds gesture that reveals the manual MLS migration debug action.
    private var protocolRowTapTimestamps: [Date] = []

    private static let manualMigrationTapThreshold = 5
    private static let manualMigrationTapWindow: TimeInterval = 5
    private static let logger = WireLogger(tag: "MLSMigrationDebugTrigger")

    // MARK: - Life cycle

    init(
        conversation: ZMConversation?,
        messageProtocol: MessageProtocol,
        groupID: MLSGroupID? = nil,
        ciphersuite: MLSCipherSuite? = nil,
        userSession: UserSession,
        presentingViewController: UIViewController?
    ) {
        self.conversation = conversation
        self.messageProtocol = messageProtocol
        self.groupID = groupID
        self.ciphersuite = ciphersuite
        self.userSession = userSession
        self.presentingViewController = presentingViewController
        super.init()
    }

    // MARK: - Methods

    override var isHidden: Bool {
        false
    }

    override var sectionTitle: String? {
        L10n.Localizable.GroupDetails.MessageProtocol.sectionTile.uppercased()
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        guard let collectionView else { return }
        Cell.register(in: collectionView)
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard section == 0 else { return 0 }

        switch messageProtocol {
        case .proteus:
            return 1

        case .mls, .mixed:
            return 2
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Cell.zm_reuseIdentifier,
            for: indexPath
        ) as! Cell

        cell.icon = nil

        switch (messageProtocol, indexPath.row) {
        case (_, 0):
            cell.accessibilityIdentifier = "cell.groupdetails.message_protocol"
            cell.title = L10n.Localizable.GroupDetails.MessageProtocol.title
            cell.status = messageProtocol.name

        case (.mls, 1), (.mixed, 1):
            cell.accessibilityIdentifier = "cell.groupdetails.cipher_suite"
            cell.title = L10n.Localizable.GroupDetails.MessageProtocol.cipherSuite
            cell.status = ciphersuite?.description ?? ""
            cell.allowMultilineStatus = true

        default:
            break
        }

        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        var size = super.collectionView(
            collectionView,
            layout: collectionViewLayout,
            sizeForItemAt: indexPath
        )

        // We need a little bit more height for the cipher suite text.
        if indexPath.row == 1 {
            size.height += 16
        }

        return size
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard indexPath.row == 0 else { return }
        Task {
            await registerProtocolRowTap()
        }
    }

    // MARK: - Manual MLS migration debug trigger

    @MainActor
    private func registerProtocolRowTap() async {
        let now = Date()
        protocolRowTapTimestamps = protocolRowTapTimestamps.filter {
            now.timeIntervalSince($0) <= Self.manualMigrationTapWindow
        }
        protocolRowTapTimestamps.append(now)
        Self.logger
            .debug(
                "protocol row tapped (\(protocolRowTapTimestamps.count)/\(Self.manualMigrationTapThreshold) in window)"
            )

        guard protocolRowTapTimestamps.count >= Self.manualMigrationTapThreshold else { return }
        protocolRowTapTimestamps.removeAll()

        guard await canTriggerManualMLSMigration else {
            Self.logger.debug("manual MLS migration trigger denied, eligibility checks failed")
            return
        }
        requestMLSMigration()
    }

    private var canTriggerManualMLSMigration: Bool {
        get async {
            guard messageProtocol == .proteus || messageProtocol == .mixed else {
                Self.logger
                    .debug("manual MLS migration denied: message protocol is \(String(describing: messageProtocol))")
                return false
            }

            guard let conversation, let managedObjectContext = conversation.managedObjectContext else {
                Self.logger.debug("manual MLS migration denied: no conversation/context")
                return false
            }

            let selfUser = ZMUser.selfUser(in: managedObjectContext)
            guard selfUser.isGroupAdmin(in: conversation) else {
                Self.logger.debug("manual MLS migration denied: self user is not group admin")
                return false
            }

            let isMLSMigrationFeatureEnabled = await userSession.clientSessionComponent?
                .featureConfigRepository.isFeatureEnabled(.mlsMigration) ?? false

            if !isMLSMigrationFeatureEnabled {
                Self.logger.debug("manual MLS migration denied: mlsMigration feature is not enabled")
            }

            return isMLSMigrationFeatureEnabled
        }
    }

}

private extension MessageProtocol {

    var name: String {
        switch self {
        case .proteus:
            "Proteus"

        case .mls:
            "MLS"

        case .mixed:
            "Mixed"
        }
    }

}
