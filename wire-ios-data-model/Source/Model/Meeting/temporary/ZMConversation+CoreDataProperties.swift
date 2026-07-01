//
//  ZMConversation+CoreDataProperties.swift
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData
import WireDataModel

public typealias ZMConversationCoreDataPropertiesSet = NSSet

extension ZMConversation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ZMConversation> {
        return NSFetchRequest<ZMConversation>(entityName: "Conversation")
    }

    @NSManaged public var accessModeStrings: NSObject?
    @NSManaged public var accessRoleString: String?
    @NSManaged public var accessRoleStringsV2: NSObject?
    @NSManaged public var archivedChangedTimestamp: Date?
    @NSManaged public var cellName: String?
    @NSManaged public var cellsState: Int16
    @NSManaged public var ciphersuite: NSNumber?
    @NSManaged public var clearedTimeStamp: Date?
    @NSManaged public var commitPendingProposalDate: Date?
    @NSManaged public var conversationType: NSNumber?
    @NSManaged public var domain: String?
    @NSManaged public var draftMessageData: Data?
    @NSManaged public var draftMessageNonce: Data?
    @NSManaged public var effectiveConversationType: NSNumber?
    @NSManaged public var epoch: NSNumber?
    @NSManaged public var groupType: NSNumber?
    @NSManaged public var hasReadReceiptsEnabled: NSNumber?
    @NSManaged public var hasUnreadUnsentMessage: NSNumber?
    @NSManaged public var internalEstimatedUnreadCount: NSNumber?
    @NSManaged public var internalEstimatedUnreadSelfMentionCount: NSNumber?
    @NSManaged public var internalEstimatedUnreadSelfReplyCount: NSNumber?
    @NSManaged public var internalIsArchived: NSNumber?
    @NSManaged public var isDeletedRemotely: NSNumber?
    @NSManaged public var isForcedReadOnly: NSNumber?
    @NSManaged public var isPendingInitialFetch: Bool
    @NSManaged public var isPendingMetadataRefresh: NSNumber?
    @NSManaged public var isSelfAnActiveMember: NSNumber?
    @NSManaged public var language: String?
    @NSManaged public var lastModifiedDate: Date?
    @NSManaged public var lastReadServerTimeStamp: Date?
    @NSManaged public var lastServerTimeStamp: Date?
    @NSManaged public var lastUnreadKnockDate: Date?
    @NSManaged public var lastUnreadMissedCallDate: Date?
    @NSManaged public var legalHoldStatus: NSNumber?
    @NSManaged public var localMessageDestructionTimeout: NSNumber?
    @NSManaged public var messageProtocol: NSNumber?
    @NSManaged public var migratedToMLS: Bool
    @NSManaged public var mlsGroupID: Data?
    @NSManaged public var mlsStatus: NSNumber?
    @NSManaged public var mlsVerificationStatus: Int16
    @NSManaged public var modifiedKeys: NSObject?
    @NSManaged public var mutedStatus: NSNumber?
    @NSManaged public var needsToBeUpdatedFromBackend: NSNumber?
    @NSManaged public var needsToCalculateUnreadMessages: NSNumber?
    @NSManaged public var needsToDownloadRoles: NSNumber?
    @NSManaged public var needsToVerifyLegalHold: NSNumber?
    @NSManaged public var normalizedUserDefinedName: String?
    @NSManaged public var primaryKey: String?
    @NSManaged public var privateChannelPermission: Int16
    @NSManaged public var remoteIdentifier: NSObject?
    @NSManaged public var remoteIdentifier_data: Data?
    @NSManaged public var securityLevel: NSNumber?
    @NSManaged public var silencedChangedTimestamp: Date?
    @NSManaged public var syncedMessageDestructionTimeout: NSNumber?
    @NSManaged public var teamRemoteIdentifier: NSObject?
    @NSManaged public var teamRemoteIdentifier_data: Data?
    @NSManaged public var userDefinedName: String?
    @NSManaged public var voiceChannel: NSObject?
    @NSManaged public var allMessages: NSSet?
    @NSManaged public var creator: ZMUser?
    @NSManaged public var hiddenMessages: NSSet?
    @NSManaged public var labels: NSSet?
    @NSManaged public var lastServerSyncedActiveParticipants: NSOrderedSet?
    @NSManaged public var nonTeamRoles: NSSet?
    @NSManaged public var oneOnOneUser: ZMUser?
    @NSManaged public var parentMeeting: StoredMeeting?
    @NSManaged public var participantRoles: NSSet?
    @NSManaged public var team: Team?
    @NSManaged public var wireCellsMessageAttachmentDrafts: NSSet?

}

// MARK: Generated accessors for allMessages
extension ZMConversation {

    @objc(addAllMessagesObject:)
    @NSManaged public func addToAllMessages(_ value: ZMMessage)

    @objc(removeAllMessagesObject:)
    @NSManaged public func removeFromAllMessages(_ value: ZMMessage)

    @objc(addAllMessages:)
    @NSManaged public func addToAllMessages(_ values: NSSet)

    @objc(removeAllMessages:)
    @NSManaged public func removeFromAllMessages(_ values: NSSet)

}

// MARK: Generated accessors for hiddenMessages
extension ZMConversation {

    @objc(addHiddenMessagesObject:)
    @NSManaged public func addToHiddenMessages(_ value: ZMMessage)

    @objc(removeHiddenMessagesObject:)
    @NSManaged public func removeFromHiddenMessages(_ value: ZMMessage)

    @objc(addHiddenMessages:)
    @NSManaged public func addToHiddenMessages(_ values: NSSet)

    @objc(removeHiddenMessages:)
    @NSManaged public func removeFromHiddenMessages(_ values: NSSet)

}

// MARK: Generated accessors for labels
extension ZMConversation {

    @objc(addLabelsObject:)
    @NSManaged public func addToLabels(_ value: Label)

    @objc(removeLabelsObject:)
    @NSManaged public func removeFromLabels(_ value: Label)

    @objc(addLabels:)
    @NSManaged public func addToLabels(_ values: NSSet)

    @objc(removeLabels:)
    @NSManaged public func removeFromLabels(_ values: NSSet)

}

// MARK: Generated accessors for lastServerSyncedActiveParticipants
extension ZMConversation {

    @objc(insertObject:inLastServerSyncedActiveParticipantsAtIndex:)
    @NSManaged public func insertIntoLastServerSyncedActiveParticipants(_ value: ZMUser, at idx: Int)

    @objc(removeObjectFromLastServerSyncedActiveParticipantsAtIndex:)
    @NSManaged public func removeFromLastServerSyncedActiveParticipants(at idx: Int)

    @objc(insertLastServerSyncedActiveParticipants:atIndexes:)
    @NSManaged public func insertIntoLastServerSyncedActiveParticipants(_ values: [ZMUser], at indexes: NSIndexSet)

    @objc(removeLastServerSyncedActiveParticipantsAtIndexes:)
    @NSManaged public func removeFromLastServerSyncedActiveParticipants(at indexes: NSIndexSet)

    @objc(replaceObjectInLastServerSyncedActiveParticipantsAtIndex:withObject:)
    @NSManaged public func replaceLastServerSyncedActiveParticipants(at idx: Int, with value: ZMUser)

    @objc(replaceLastServerSyncedActiveParticipantsAtIndexes:withLastServerSyncedActiveParticipants:)
    @NSManaged public func replaceLastServerSyncedActiveParticipants(at indexes: NSIndexSet, with values: [ZMUser])

    @objc(addLastServerSyncedActiveParticipantsObject:)
    @NSManaged public func addToLastServerSyncedActiveParticipants(_ value: ZMUser)

    @objc(removeLastServerSyncedActiveParticipantsObject:)
    @NSManaged public func removeFromLastServerSyncedActiveParticipants(_ value: ZMUser)

    @objc(addLastServerSyncedActiveParticipants:)
    @NSManaged public func addToLastServerSyncedActiveParticipants(_ values: NSOrderedSet)

    @objc(removeLastServerSyncedActiveParticipants:)
    @NSManaged public func removeFromLastServerSyncedActiveParticipants(_ values: NSOrderedSet)

}

// MARK: Generated accessors for nonTeamRoles
extension ZMConversation {

    @objc(addNonTeamRolesObject:)
    @NSManaged public func addToNonTeamRoles(_ value: Role)

    @objc(removeNonTeamRolesObject:)
    @NSManaged public func removeFromNonTeamRoles(_ value: Role)

    @objc(addNonTeamRoles:)
    @NSManaged public func addToNonTeamRoles(_ values: NSSet)

    @objc(removeNonTeamRoles:)
    @NSManaged public func removeFromNonTeamRoles(_ values: NSSet)

}

// MARK: Generated accessors for participantRoles
extension ZMConversation {

    @objc(addParticipantRolesObject:)
    @NSManaged public func addToParticipantRoles(_ value: ParticipantRole)

    @objc(removeParticipantRolesObject:)
    @NSManaged public func removeFromParticipantRoles(_ value: ParticipantRole)

    @objc(addParticipantRoles:)
    @NSManaged public func addToParticipantRoles(_ values: NSSet)

    @objc(removeParticipantRoles:)
    @NSManaged public func removeFromParticipantRoles(_ values: NSSet)

}

// MARK: Generated accessors for wireCellsMessageAttachmentDrafts
extension ZMConversation {

    @objc(addWireCellsMessageAttachmentDraftsObject:)
    @NSManaged public func addToWireCellsMessageAttachmentDrafts(_ value: WireCellsMessageAttachmentDraftEntity)

    @objc(removeWireCellsMessageAttachmentDraftsObject:)
    @NSManaged public func removeFromWireCellsMessageAttachmentDrafts(_ value: WireCellsMessageAttachmentDraftEntity)

    @objc(addWireCellsMessageAttachmentDrafts:)
    @NSManaged public func addToWireCellsMessageAttachmentDrafts(_ values: NSSet)

    @objc(removeWireCellsMessageAttachmentDrafts:)
    @NSManaged public func removeFromWireCellsMessageAttachmentDrafts(_ values: NSSet)

}

extension ZMConversation : Identifiable {

}
