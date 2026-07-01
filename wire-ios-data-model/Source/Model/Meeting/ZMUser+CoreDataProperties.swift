//
//  ZMUser+CoreDataProperties.swift
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData
import WireData
import WireDataModel

public typealias ZMUserCoreDataPropertiesSet = NSSet

extension ZMUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ZMUser> {
        return NSFetchRequest<ZMUser>(entityName: "User")
    }

    @NSManaged public var accentColorValue: NSNumber?
    @NSManaged public var analyticsIdentifier: String?
    @NSManaged public var availability: NSNumber?
    @NSManaged public var completeProfileAssetIdentifier: String?
    @NSManaged public var domain: String?
    @NSManaged public var emailAddress: String?
    @NSManaged public var expiresAt: Date?
    @NSManaged public var handle: String?
    @NSManaged public var isAccountDeleted: NSNumber?
    @NSManaged public var isPendingMetadataRefresh: NSNumber?
    @NSManaged public var legalHoldRequest: Data?
    @NSManaged public var managedBy: String?
    @NSManaged public var modifiedKeys: NSObject?
    @NSManaged public var name: String?
    @NSManaged public var needsPropertiesUpdate: NSNumber?
    @NSManaged public var needsRichProfileUpdate: NSNumber?
    @NSManaged public var needsToAcknowledgeLegalHoldStatus: NSNumber?
    @NSManaged public var needsToBeUpdatedFromBackend: NSNumber?
    @NSManaged public var needsToRefetchLabels: NSNumber?
    @NSManaged public var normalizedEmailAddress: String?
    @NSManaged public var normalizedName: String?
    @NSManaged public var previewProfileAssetIdentifier: String?
    @NSManaged public var primaryKey: String?
    @NSManaged public var providerIdentifier: String?
    @NSManaged public var readReceiptsEnabled: NSNumber?
    @NSManaged public var readReceiptsEnabledChangedRemotely: NSNumber?
    @NSManaged public var remoteIdentifier: NSObject?
    @NSManaged public var remoteIdentifier_data: Data?
    @NSManaged public var richProfile: Data?
    @NSManaged public var serviceIdentifier: String?
    @NSManaged public var supportedProtocols: NSObject?
    @NSManaged public var teamIdentifier: NSObject?
    @NSManaged public var teamIdentifier_data: Data?
    @NSManaged public var typeValue: Int16
    @NSManaged public var usesCompanyLogin: NSNumber?
    @NSManaged public var addressBookEntry: AddressBookEntry?
    @NSManaged public var appInfo: AppInfo?
    @NSManaged public var clients: NSSet?
    @NSManaged public var connection: ZMConnection?
    @NSManaged public var conversationsCreated: NSSet?
    @NSManaged public var createdMeetings: NSSet?
    @NSManaged public var createdTeamMembers: NSSet?
    @NSManaged public var createdTeams: NSSet?
    @NSManaged public var lastServerSyncedActiveConversations: NSOrderedSet?
    @NSManaged public var membership: Member?
    @NSManaged public var messagesFailedToSendRecipient: NSSet?
    @NSManaged public var oneOnOneConversation: ZMConversation?
    @NSManaged public var participantRoles: NSSet?
    @NSManaged public var reactions: NSSet?
    @NSManaged public var showingUserAdded: NSSet?
    @NSManaged public var showingUserRemoved: NSSet?
    @NSManaged public var systemMessages: NSSet?

}

// MARK: Generated accessors for clients
extension ZMUser {

    @objc(addClientsObject:)
    @NSManaged public func addToClients(_ value: UserClient)

    @objc(removeClientsObject:)
    @NSManaged public func removeFromClients(_ value: UserClient)

    @objc(addClients:)
    @NSManaged public func addToClients(_ values: NSSet)

    @objc(removeClients:)
    @NSManaged public func removeFromClients(_ values: NSSet)

}

// MARK: Generated accessors for conversationsCreated
extension ZMUser {

    @objc(addConversationsCreatedObject:)
    @NSManaged public func addToConversationsCreated(_ value: ZMConversation)

    @objc(removeConversationsCreatedObject:)
    @NSManaged public func removeFromConversationsCreated(_ value: ZMConversation)

    @objc(addConversationsCreated:)
    @NSManaged public func addToConversationsCreated(_ values: NSSet)

    @objc(removeConversationsCreated:)
    @NSManaged public func removeFromConversationsCreated(_ values: NSSet)

}

// MARK: Generated accessors for createdMeetings
extension ZMUser {

    @objc(addCreatedMeetingsObject:)
    @NSManaged public func addToCreatedMeetings(_ value: StoredMeetingMeeting)

    @objc(removeCreatedMeetingsObject:)
    @NSManaged public func removeFromCreatedMeetings(_ value: StoredMeetingMeeting)

    @objc(addCreatedMeetings:)
    @NSManaged public func addToCreatedMeetings(_ values: NSSet)

    @objc(removeCreatedMeetings:)
    @NSManaged public func removeFromCreatedMeetings(_ values: NSSet)

}

// MARK: Generated accessors for createdTeamMembers
extension ZMUser {

    @objc(addCreatedTeamMembersObject:)
    @NSManaged public func addToCreatedTeamMembers(_ value: Member)

    @objc(removeCreatedTeamMembersObject:)
    @NSManaged public func removeFromCreatedTeamMembers(_ value: Member)

    @objc(addCreatedTeamMembers:)
    @NSManaged public func addToCreatedTeamMembers(_ values: NSSet)

    @objc(removeCreatedTeamMembers:)
    @NSManaged public func removeFromCreatedTeamMembers(_ values: NSSet)

}

// MARK: Generated accessors for createdTeams
extension ZMUser {

    @objc(addCreatedTeamsObject:)
    @NSManaged public func addToCreatedTeams(_ value: Team)

    @objc(removeCreatedTeamsObject:)
    @NSManaged public func removeFromCreatedTeams(_ value: Team)

    @objc(addCreatedTeams:)
    @NSManaged public func addToCreatedTeams(_ values: NSSet)

    @objc(removeCreatedTeams:)
    @NSManaged public func removeFromCreatedTeams(_ values: NSSet)

}

// MARK: Generated accessors for lastServerSyncedActiveConversations
extension ZMUser {

    @objc(insertObject:inLastServerSyncedActiveConversationsAtIndex:)
    @NSManaged public func insertIntoLastServerSyncedActiveConversations(_ value: ZMConversation, at idx: Int)

    @objc(removeObjectFromLastServerSyncedActiveConversationsAtIndex:)
    @NSManaged public func removeFromLastServerSyncedActiveConversations(at idx: Int)

    @objc(insertLastServerSyncedActiveConversations:atIndexes:)
    @NSManaged public func insertIntoLastServerSyncedActiveConversations(_ values: [ZMConversation], at indexes: NSIndexSet)

    @objc(removeLastServerSyncedActiveConversationsAtIndexes:)
    @NSManaged public func removeFromLastServerSyncedActiveConversations(at indexes: NSIndexSet)

    @objc(replaceObjectInLastServerSyncedActiveConversationsAtIndex:withObject:)
    @NSManaged public func replaceLastServerSyncedActiveConversations(at idx: Int, with value: ZMConversation)

    @objc(replaceLastServerSyncedActiveConversationsAtIndexes:withLastServerSyncedActiveConversations:)
    @NSManaged public func replaceLastServerSyncedActiveConversations(at indexes: NSIndexSet, with values: [ZMConversation])

    @objc(addLastServerSyncedActiveConversationsObject:)
    @NSManaged public func addToLastServerSyncedActiveConversations(_ value: ZMConversation)

    @objc(removeLastServerSyncedActiveConversationsObject:)
    @NSManaged public func removeFromLastServerSyncedActiveConversations(_ value: ZMConversation)

    @objc(addLastServerSyncedActiveConversations:)
    @NSManaged public func addToLastServerSyncedActiveConversations(_ values: NSOrderedSet)

    @objc(removeLastServerSyncedActiveConversations:)
    @NSManaged public func removeFromLastServerSyncedActiveConversations(_ values: NSOrderedSet)

}

// MARK: Generated accessors for messagesFailedToSendRecipient
extension ZMUser {

    @objc(addMessagesFailedToSendRecipientObject:)
    @NSManaged public func addToMessagesFailedToSendRecipient(_ value: ZMMessage)

    @objc(removeMessagesFailedToSendRecipientObject:)
    @NSManaged public func removeFromMessagesFailedToSendRecipient(_ value: ZMMessage)

    @objc(addMessagesFailedToSendRecipient:)
    @NSManaged public func addToMessagesFailedToSendRecipient(_ values: NSSet)

    @objc(removeMessagesFailedToSendRecipient:)
    @NSManaged public func removeFromMessagesFailedToSendRecipient(_ values: NSSet)

}

// MARK: Generated accessors for participantRoles
extension ZMUser {

    @objc(addParticipantRolesObject:)
    @NSManaged public func addToParticipantRoles(_ value: ParticipantRole)

    @objc(removeParticipantRolesObject:)
    @NSManaged public func removeFromParticipantRoles(_ value: ParticipantRole)

    @objc(addParticipantRoles:)
    @NSManaged public func addToParticipantRoles(_ values: NSSet)

    @objc(removeParticipantRoles:)
    @NSManaged public func removeFromParticipantRoles(_ values: NSSet)

}

// MARK: Generated accessors for reactions
extension ZMUser {

    @objc(addReactionsObject:)
    @NSManaged public func addToReactions(_ value: Reaction)

    @objc(removeReactionsObject:)
    @NSManaged public func removeFromReactions(_ value: Reaction)

    @objc(addReactions:)
    @NSManaged public func addToReactions(_ values: NSSet)

    @objc(removeReactions:)
    @NSManaged public func removeFromReactions(_ values: NSSet)

}

// MARK: Generated accessors for showingUserAdded
extension ZMUser {

    @objc(addShowingUserAddedObject:)
    @NSManaged public func addToShowingUserAdded(_ value: ZMSystemMessage)

    @objc(removeShowingUserAddedObject:)
    @NSManaged public func removeFromShowingUserAdded(_ value: ZMSystemMessage)

    @objc(addShowingUserAdded:)
    @NSManaged public func addToShowingUserAdded(_ values: NSSet)

    @objc(removeShowingUserAdded:)
    @NSManaged public func removeFromShowingUserAdded(_ values: NSSet)

}

// MARK: Generated accessors for showingUserRemoved
extension ZMUser {

    @objc(addShowingUserRemovedObject:)
    @NSManaged public func addToShowingUserRemoved(_ value: ZMSystemMessage)

    @objc(removeShowingUserRemovedObject:)
    @NSManaged public func removeFromShowingUserRemoved(_ value: ZMSystemMessage)

    @objc(addShowingUserRemoved:)
    @NSManaged public func addToShowingUserRemoved(_ values: NSSet)

    @objc(removeShowingUserRemoved:)
    @NSManaged public func removeFromShowingUserRemoved(_ values: NSSet)

}

// MARK: Generated accessors for systemMessages
extension ZMUser {

    @objc(addSystemMessagesObject:)
    @NSManaged public func addToSystemMessages(_ value: ZMSystemMessage)

    @objc(removeSystemMessagesObject:)
    @NSManaged public func removeFromSystemMessages(_ value: ZMSystemMessage)

    @objc(addSystemMessages:)
    @NSManaged public func addToSystemMessages(_ values: NSSet)

    @objc(removeSystemMessages:)
    @NSManaged public func removeFromSystemMessages(_ values: NSSet)

}

extension ZMUser : Identifiable {

}
