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

/// Configurations for various app features.

public enum FeatureConfig: Equatable, Sendable {

    /// Config for the *App Lock* feature.
    ///
    /// *App Lock* protects user content by locking the
    /// app after it has been backgrounded, then requiring
    /// user authentication to unlock it again.

    case appLock(AppLockFeatureConfig)

    /// Config for the *Apps* feature.

    case apps(AppsFeatureConfig)

    /// Config for the *Classified Domains* feature.`
    ///
    /// *Classified Domains* are a list of backend domains
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

    /// Config for the *Consumable Notifications* feature.`
    ///
    /// *Consumable Notifications* is the `new` synchronization mechanism (often referred to as `quick sync`) to ensure
    /// the app is up to date.

    case consumableNotifications(ConsumableNotificationsFeatureConfig)

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

    /// Config for **Channels** feature
    ///
    /// **Channels** are discoverable groups
    /// with history sharing capabilities
    case channels(ChannelsFeatureConfig)

    /// Config for **Cells** feature
    /// **Cells** allow users to send and receive messages with multiple attachments (video, image, files..)
    case cells(CellsFeatureConfig)

    /// Config for **Cells** (internal) feature
    /// Provides the proper cells backend URL.
    case cellsInternal(CellsInternalFeatureConfig)

    /// Global config, that contains other config inside, e.g. 'reset broken mls'

    case allowedGlobalOperations(AllowedGlobalOperationsFeatureConfig)

    /// Config for "Asset Audit Log" feature.
    ///
    /// When this feature is enabled, additional metadata is provided
    /// to the backend when uploading an asset so that an audit log
    /// can be constructed for future referece, such as for security
    /// review.

    case assetAuditLog(AssetAuditLogFeatureConfig)

    /// An unknown feature.

    case unknown(featureName: String)

}
