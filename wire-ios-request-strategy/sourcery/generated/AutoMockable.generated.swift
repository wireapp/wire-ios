// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif


@testable import WireRequestStrategy





















class MockConversationParticipantsServiceInterface: ConversationParticipantsServiceInterface {

    // MARK: - Life cycle



    // MARK: - addParticipants

    var addParticipantsToCompletion_Invocations: [(users: [ZMUser], conversation: ZMConversation, completion: AddParticipantAction.ResultHandler)] = []
    var addParticipantsToCompletion_MockMethod: (([ZMUser], ZMConversation, @escaping AddParticipantAction.ResultHandler) -> Void)?

    func addParticipants(_ users: [ZMUser], to conversation: ZMConversation, completion: @escaping AddParticipantAction.ResultHandler) {
        addParticipantsToCompletion_Invocations.append((users: users, conversation: conversation, completion: completion))

        guard let mock = addParticipantsToCompletion_MockMethod else {
            fatalError("no mock for `addParticipantsToCompletion`")
        }

        mock(users, conversation, completion)            
    }

    // MARK: - removeParticipant

    var removeParticipantFromCompletion_Invocations: [(user: ZMUser, conversation: ZMConversation, completion: RemoveParticipantAction.ResultHandler)] = []
    var removeParticipantFromCompletion_MockMethod: ((ZMUser, ZMConversation, @escaping RemoveParticipantAction.ResultHandler) -> Void)?

    func removeParticipant(_ user: ZMUser, from conversation: ZMConversation, completion: @escaping RemoveParticipantAction.ResultHandler) {
        removeParticipantFromCompletion_Invocations.append((user: user, conversation: conversation, completion: completion))

        guard let mock = removeParticipantFromCompletion_MockMethod else {
            fatalError("no mock for `removeParticipantFromCompletion`")
        }

        mock(user, conversation, completion)            
    }

}
public class MockConversationServiceInterface: ConversationServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - createGroupConversation

    public var createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_Invocations: [(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void)] = []
    public var createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_MockMethod: ((String?, Set<ZMUser>, Bool, Bool, Bool, MessageProtocol, @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) -> Void)?

    public func createGroupConversation(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) {
        createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_Invocations.append((name: name, users: users, allowGuests: allowGuests, allowServices: allowServices, enableReceipts: enableReceipts, messageProtocol: messageProtocol, completion: completion))

        guard let mock = createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_MockMethod else {
            fatalError("no mock for `createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion`")
        }

        mock(name, users, allowGuests, allowServices, enableReceipts, messageProtocol, completion)            
    }

    // MARK: - syncConversation

    public var syncConversationQualifiedIDCompletion_Invocations: [(qualifiedID: QualifiedID, completion: () -> Void)] = []
    public var syncConversationQualifiedIDCompletion_MockMethod: ((QualifiedID, @escaping () -> Void) -> Void)?

    public func syncConversation(qualifiedID: QualifiedID, completion: @escaping () -> Void) {
        syncConversationQualifiedIDCompletion_Invocations.append((qualifiedID: qualifiedID, completion: completion))

        guard let mock = syncConversationQualifiedIDCompletion_MockMethod else {
            fatalError("no mock for `syncConversationQualifiedIDCompletion`")
        }

        mock(qualifiedID, completion)            
    }

    // MARK: - addParticipants

    public var addParticipantsToCompletion_Invocations: [(participants: [UserType], conversation: ZMConversation, completion: AddParticipantAction.ResultHandler)] = []
    public var addParticipantsToCompletion_MockMethod: (([UserType], ZMConversation, @escaping AddParticipantAction.ResultHandler) -> Void)?

    public func addParticipants(_ participants: [UserType], to conversation: ZMConversation, completion: @escaping AddParticipantAction.ResultHandler) {
        addParticipantsToCompletion_Invocations.append((participants: participants, conversation: conversation, completion: completion))

        guard let mock = addParticipantsToCompletion_MockMethod else {
            fatalError("no mock for `addParticipantsToCompletion`")
        }

        mock(participants, conversation, completion)            
    }

    // MARK: - removeParticipant

    public var removeParticipantFromCompletion_Invocations: [(participant: UserType, conversation: ZMConversation, completion: RemoveParticipantAction.ResultHandler)] = []
    public var removeParticipantFromCompletion_MockMethod: ((UserType, ZMConversation, @escaping RemoveParticipantAction.ResultHandler) -> Void)?

    public func removeParticipant(_ participant: UserType, from conversation: ZMConversation, completion: @escaping RemoveParticipantAction.ResultHandler) {
        removeParticipantFromCompletion_Invocations.append((participant: participant, conversation: conversation, completion: completion))

        guard let mock = removeParticipantFromCompletion_MockMethod else {
            fatalError("no mock for `removeParticipantFromCompletion`")
        }

        mock(participant, conversation, completion)            
    }

}
class MockMLSConversationParticipantsServiceInterface: MLSConversationParticipantsServiceInterface {

    // MARK: - Life cycle



    // MARK: - addParticipants

    var addParticipantsToCompletion_Invocations: [(users: [ZMUser], conversation: ZMConversation, completion: AddParticipantAction.ResultHandler)] = []
    var addParticipantsToCompletion_MockMethod: (([ZMUser], ZMConversation, @escaping AddParticipantAction.ResultHandler) -> Void)?

    func addParticipants(_ users: [ZMUser], to conversation: ZMConversation, completion: @escaping AddParticipantAction.ResultHandler) {
        addParticipantsToCompletion_Invocations.append((users: users, conversation: conversation, completion: completion))

        guard let mock = addParticipantsToCompletion_MockMethod else {
            fatalError("no mock for `addParticipantsToCompletion`")
        }

        mock(users, conversation, completion)            
    }

    // MARK: - removeParticipant

    var removeParticipantFromCompletion_Invocations: [(user: ZMUser, conversation: ZMConversation, completion: RemoveParticipantAction.ResultHandler)] = []
    var removeParticipantFromCompletion_MockMethod: ((ZMUser, ZMConversation, @escaping RemoveParticipantAction.ResultHandler) -> Void)?

    func removeParticipant(_ user: ZMUser, from conversation: ZMConversation, completion: @escaping RemoveParticipantAction.ResultHandler) {
        removeParticipantFromCompletion_Invocations.append((user: user, conversation: conversation, completion: completion))

        guard let mock = removeParticipantFromCompletion_MockMethod else {
            fatalError("no mock for `removeParticipantFromCompletion`")
        }

        mock(user, conversation, completion)            
    }

}
class MockProteusConversationParticipantsServiceInterface: ProteusConversationParticipantsServiceInterface {

    // MARK: - Life cycle



    // MARK: - addParticipants

    var addParticipantsToCompletion_Invocations: [(users: [ZMUser], conversation: ZMConversation, completion: AddParticipantAction.ResultHandler)] = []
    var addParticipantsToCompletion_MockMethod: (([ZMUser], ZMConversation, @escaping AddParticipantAction.ResultHandler) -> Void)?

    func addParticipants(_ users: [ZMUser], to conversation: ZMConversation, completion: @escaping AddParticipantAction.ResultHandler) {
        addParticipantsToCompletion_Invocations.append((users: users, conversation: conversation, completion: completion))

        guard let mock = addParticipantsToCompletion_MockMethod else {
            fatalError("no mock for `addParticipantsToCompletion`")
        }

        mock(users, conversation, completion)            
    }

    // MARK: - removeParticipant

    var removeParticipantFromCompletion_Invocations: [(user: ZMUser, conversation: ZMConversation, completion: RemoveParticipantAction.ResultHandler)] = []
    var removeParticipantFromCompletion_MockMethod: ((ZMUser, ZMConversation, @escaping RemoveParticipantAction.ResultHandler) -> Void)?

    func removeParticipant(_ user: ZMUser, from conversation: ZMConversation, completion: @escaping RemoveParticipantAction.ResultHandler) {
        removeParticipantFromCompletion_Invocations.append((user: user, conversation: conversation, completion: completion))

        guard let mock = removeParticipantFromCompletion_MockMethod else {
            fatalError("no mock for `removeParticipantFromCompletion`")
        }

        mock(user, conversation, completion)            
    }

}
