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

import Foundation

/// Configurations for various app features.

public enum FeatureConfig: Equatable, Codable, Sendable {

    /// Config for the *App Lock* feature.
    ///
    /// *App Lock* protects user content by locking the
    /// app after it has been backgrounded, then requiring
    /// user authentication to unlock it again.

    case appLock(AppLockFeatureConfig)

    /// Config for the *Classfied Domains* feature.`
    ///
    /// *Classfied Domains* are a list of backend domains
    /// considered to be safe for classified communication.
    /// Conversations containing users from only classified
    /// domains will show a "Classified" banner. Conversations
    /// with a mix of classified and un-classified users will
    /// show an "Not classified" banner.

    case classifiedDomains(ClassifiedDomainsFeatureConfig)

    /// Config for the *Conference Calling* feature.
    ///
    /// *Conference Calling* is group audio and video calling.

    case conferenceCalling(ConferenceCallingFeatureConfig)

    /// Config for the *Conversation Guest Links* feature.`
    ///
    /// *Conversation Guest Links* enable a group admin to create
    /// a link with with other users can join the group.

    case conversationGuestLinks(ConversationGuestLinksFeatureConfig)

    /// Config for the *Digital Signature* feature.`
    ///
    /// *Digital Signature* enables users to digitally
    /// sign documents received in conversations.

    case digitalSignature(DigitalSignatureFeatureConfig)

    /// Config for the *End To End Identity* feature.
    ///
    /// *End To End Identity* enables users to cryptographically
    /// verify the identities of other users.

    case endToEndIdentity(EndToEndIdentityFeatureConfig)

    /// Config for the `File Sharing` feature.
    ///
    /// *File Sharing* enables users to send and
    /// receive files through conversations.

    case fileSharing(FileSharingFeatureConfig)

    /// Config for the *MLS* feature.
    ///
    /// *MLS* is a next generation messaging protocol
    /// that enables efficient end to end encrypted
    /// communication within very large groups.

    case mls(MLSFeatureConfig)

    /// Config for the *MLS Migration* feature.
    ///
    /// *MLS Migration* enables a team currently using
    /// the Proteus protocol to migrate existing
    /// conversations to use the MLS protocol.`

    case mlsMigration(MLSMigrationFeatureConfig)

    /// Config for the *Self Deleting Messages* feature.
    ///
    /// *Self Deleting Messages* enables team admins
    /// to mandate all messages be self deleting
    /// after a specified time.

    case selfDeletingMessages(SelfDeletingMessagesFeatureConfig)

    /// An unknown feature.

    case unknown(featureName: String)

}
