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

import SwiftUI
import WireDesign
public import WireMessagingDomain

@MainActor
public class ConversationSharedDriveOptionsViewModel: ObservableObject {
    @Published var participants: [WireDriveParticipant]
    @Published var isSharedDriveEnabled = true

    public init(participants: [WireDriveParticipant]) {
        self.participants = participants.sorted(by: { $0.displayName < $1.displayName })
    }

    func blockedOrPendingApprovalAvatarIcon(for participant: WireDriveParticipant) -> UIImage? {
        switch participant.state {
        case .none:
            nil
        case .pendingApproval:
            StyleKitIcon.clock.makeImage(size: .tiny, color: .black).withRenderingMode(.alwaysTemplate)
        case .blocked:
            StyleKitIcon.block.makeImage(size: .tiny, color: .black).withRenderingMode(.alwaysTemplate)
        }
    }

    func trailingImages(for participant: WireDriveParticipant) -> [UIImage] {
        let verificationBadges = participant.verificationBadges.compactMap {
            switch $0 {
            case .e2EICertified:
                UIImage(resource: .certificateValid)
            case .proteusVerified:
                UIImage(resource: .verified)
            }
        }

        let userTypeBadge: UIImage? = switch participant.userType {
        case .federated:
            StyleKitIcon.federated.makeImage(size: .tiny, color: .black).withRenderingMode(.alwaysTemplate)
        case .external:
            StyleKitIcon.externalPartner.makeImage(size: .tiny, color: .black).withRenderingMode(.alwaysTemplate)
        case .member:
            nil
        case .guest:
            StyleKitIcon.guest.makeImage(size: .tiny, color: .black).withRenderingMode(.alwaysTemplate)
        }

        return verificationBadges + [userTypeBadge].compactMap(\.self)
    }
}
