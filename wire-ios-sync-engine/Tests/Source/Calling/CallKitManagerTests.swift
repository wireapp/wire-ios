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

import CallKit
import Foundation
import Intents
import OCMock
import WireDataModel
@testable import WireSyncEngine

class MockCallKitProvider: CXProvider {
    public var timesSetDelegateCalled = 0
    override func setDelegate(_ delegate: CXProviderDelegate?, queue: DispatchQueue?) {
        timesSetDelegateCalled += 1
    }

    public var timesReportNewIncomingCallCalled = 0
    override public func reportNewIncomingCall(
        with UUID: UUID,
        update: CXCallUpdate,
        completion: @escaping (Error?) -> Void
    ) {
        timesReportNewIncomingCallCalled += 1
    }

    public var timesReportCallUpdatedCalled = 0
    override public func reportCall(with UUID: UUID, updated update: CXCallUpdate) {
        timesReportCallUpdatedCalled += 1
    }

    public var timesReportCallEndedAtCalled = 0
    public var lastEndedReason: CXCallEndedReason = .answeredElsewhere
    public var lastEndedDate: Date?
    override func reportCall(with UUID: UUID, endedAt dateEnded: Date?, reason endedReason: CXCallEndedReason) {
        timesReportCallEndedAtCalled += 1
        lastEndedReason = endedReason
        lastEndedDate = dateEnded
    }

    public var timesReportOutgoingCallConnectedAtCalled = 0
    override func reportOutgoingCall(with UUID: UUID, connectedAt dateConnected: Date?) {
        timesReportOutgoingCallConnectedAtCalled += 1
    }

    public var timesReportOutgoingCallStartedConnectingCalled = 0
    override func reportOutgoingCall(with UUID: UUID, startedConnectingAt dateStartedConnecting: Date?) {
        timesReportOutgoingCallStartedConnectingCalled += 1
    }

    public var isInvalidated = false
    override func invalidate() {
        isInvalidated = true
    }
}

class MockCallObserver: CXCallObserver {
    public var mockCalls: [CXCall] = []

    override var calls: [CXCall] {
        mockCalls
    }
}

class MockCallKitCallController: CXCallController {
    override public var callObserver: CXCallObserver {
        mockCallObserver
    }

    public var mockTransactionErrorCode: CXErrorCodeRequestTransactionError?
    public var mockErrorCount = 0
    public var timesRequestTransactionCalled = 0
    public var requestedTransactions: [CXTransaction] = []
    public let mockCallObserver = MockCallObserver()

    override public func request(_ transaction: CXTransaction, completion: @escaping (Error?) -> Void) {
        timesRequestTransactionCalled += 1
        requestedTransactions.append(transaction)
        if mockErrorCount >= 1 {
            mockErrorCount -= 1
            completion(mockTransactionErrorCode)
        } else {
            completion(.none)
        }
    }
}

class MockCallAnswerAction: CXAnswerCallAction {
    var isFulfilled = false
    var hasFailed = false

    override func fulfill(withDateConnected dateConnected: Date) {
        isFulfilled = true
    }

    override func fail() {
        hasFailed = true
    }
}

class MockStartCallAction: CXStartCallAction {
    var isFulfilled = false
    var hasFailed = false

    override func fulfill() {
        isFulfilled = true
    }

    override func fail() {
        hasFailed = true
    }
}

class MockEndCallAction: CXEndCallAction {
    var isFulfilled = false
    var hasFailed = false

    override func fulfill() {
        isFulfilled = true
    }

    override func fail() {
        hasFailed = true
    }
}

class MockProvider: CXProvider {
    var connectingCalls: Set<UUID> = Set()
    var connectedCalls: Set<UUID> = Set()

    convenience init(foo: Bool) {
        self.init(configuration: CXProviderConfiguration())
    }

    override func reportOutgoingCall(with UUID: UUID, startedConnectingAt dateStartedConnecting: Date?) {
        connectingCalls.insert(UUID)
    }

    override func reportOutgoingCall(with UUID: UUID, connectedAt dateConnected: Date?) {
        connectedCalls.insert(UUID)
    }
}

class MockCallKitManagerDelegate: WireSyncEngine.CallKitManagerDelegate {
    var mockConversations: [WireSyncEngine.CallHandle: ZMConversation] = [:]
    func lookupConversation(
        by handle: WireSyncEngine.CallHandle,
        completionHandler: @escaping (Result<ZMConversation, Error>) -> Void
    ) {
        if let conversation = mockConversations[handle] {
            completionHandler(.success(conversation))
        } else {
            completionHandler(.failure(WireSyncEngine.ConversationLookupError.conversationDoesNotExist))
        }
    }

    var lookupConversationAndProcessPendingCallEventsCalls = 0
    func lookupConversationAndProcessPendingCallEvents(
        by handle: WireSyncEngine.CallHandle,
        completionHandler: @escaping (
            Result<ZMConversation, Error>
        ) -> Void
    ) {
        lookupConversationAndProcessPendingCallEventsCalls += 1
        lookupConversation(by: handle, completionHandler: completionHandler)
    }

    var hasEndedAllCalls = false
    func endAllCalls() {
        hasEndedAllCalls = true
    }
}

class CallKitManagerTest: DatabaseTest {
    var sut: WireSyncEngine.CallKitManager!
    var callKitProvider: MockCallKitProvider!
    var callKitController: MockCallKitCallController!
    var mockWireCallCenterV3: WireCallCenterV3Mock!
    var mockTransportSession: MockTransportSession!
    var mockCallKitManagerDelegate: MockCallKitManagerDelegate!

    func otherUser(moc: NSManagedObjectContext) -> ZMUser {
        let otherUser = ZMUser(context: moc)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Other Test User"

        return otherUser
    }

    func createOneOnOneConversation(user: ZMUser) {
        let oneToOne = ZMConversation.insertNewObject(in: uiMOC)
        oneToOne.conversationType = .oneOnOne
        oneToOne.remoteIdentifier = UUID()
        oneToOne.oneOnOneUser = user

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.status = .accepted
        connection.to = user
    }

    func conversation(type: ZMConversationType = .oneOnOne, moc: NSManagedObjectContext? = .none) -> ZMConversation {
        let moc = moc ?? uiMOC
        let conversation = ZMConversation(context: moc)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = type
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC), role: nil)

        if type == .group {
            conversation.addParticipantAndUpdateConversationState(user: otherUser(moc: moc), role: nil)
        }
        conversation.needsToBeUpdatedFromBackend = false

        return conversation
    }

    override func setUp() {
        super.setUp()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()

        let flowManager = FlowManagerMock()
        let configuration = WireSyncEngine.CallKitManager.providerConfiguration
        callKitProvider = MockCallKitProvider(configuration: configuration)
        callKitController = MockCallKitCallController()
        mockWireCallCenterV3 = WireCallCenterV3Mock(
            userId: selfUser.avsIdentifier,
            clientId: "123",
            uiMOC: uiMOC,
            flowManager: flowManager,
            transport: WireCallCenterTransportMock()
        )
        mockCallKitManagerDelegate = MockCallKitManagerDelegate()
        mockTransportSession = MockTransportSession(dispatchGroup: dispatchGroup)

        sut = CallKitManager(
            isEnabled: true,
            application: ApplicationMock(),
            requiredPushTokenType: .standard,
            provider: callKitProvider,
            callController: callKitController,
            mediaManager: nil,
            delegate: mockCallKitManagerDelegate
        )

        uiMOC.zm_callCenter = mockWireCallCenterV3
    }

    override func tearDown() {
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        sut = nil
        mockWireCallCenterV3 = nil
        mockCallKitManagerDelegate = nil
        mockTransportSession.cleanUp()
        mockTransportSession = nil

        super.tearDown()
    }

    // MARK: Provider configuration

    func testThatItReturnsTheProviderConfiguration() {
        // when
        let configuration = WireSyncEngine.CallKitManager.providerConfiguration

        // then
        XCTAssertEqual(configuration.supportsVideo, true)
        XCTAssertTrue(configuration.supportedHandleTypes.contains(.generic))
    }

    func testThatItReturnsDefaultRingSound() {
        // when
        let configuration = WireSyncEngine.CallKitManager.providerConfiguration

        // then
        XCTAssertEqual(configuration.ringtoneSound, "ringing_from_them_long.caf")
    }

    func testThatItInvalidatesTheProviderOnDeinit() {
        // given
        sut = CallKitManager(
            isEnabled: true,
            application: ApplicationMock(),
            requiredPushTokenType: .standard,
            provider: callKitProvider,
            callController: callKitController,
            mediaManager: nil,
            delegate: nil
        )

        // when
        sut = nil

        // then
        XCTAssertTrue(callKitProvider.isInvalidated)
    }

    // MARK: Reporting Actions

    func testThatItReportsTheStartCallRequest() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let user = otherUser(moc: uiMOC)
        createOneOnOneConversation(user: user)
        let conversation = user.oneToOneConversation!

        // when
        sut.requestJoinCall(in: conversation, video: false)

        // then
        XCTAssertEqual(callKitProvider.timesReportCallUpdatedCalled, 0)
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXStartCallAction)
        let action = callKitController.requestedTransactions.first!.actions.first! as! CXStartCallAction

        XCTAssertEqual(action.callUUID, sut.callRegister.lookupCall(by: conversation)?.id)
        XCTAssertEqual(action.handle.type, .generic)
        XCTAssertEqual(
            action.handle.value,
            "\(selfUser.remoteIdentifier!.transportString())+\(conversation.remoteIdentifier!.transportString())"
        )
    }

    func testThatItReportsTheStartCallRequest_groupConversation() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let conversation = conversation(type: .group)

        // when
        sut.requestJoinCall(in: conversation, video: false)

        // then
        XCTAssertEqual(callKitProvider.timesReportCallUpdatedCalled, 0)
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXStartCallAction)

        let action = callKitController.requestedTransactions.first!.actions.first! as! CXStartCallAction
        XCTAssertEqual(action.callUUID, sut.callRegister.lookupCall(by: conversation)?.id)
        XCTAssertEqual(action.handle.type, .generic)
        XCTAssertEqual(
            action.handle.value,
            "\(selfUser.remoteIdentifier!.transportString())+\(conversation.remoteIdentifier!.transportString())"
        )
        XCTAssertFalse(action.isVideo)
    }

    func testThatItReportsTheStartCallRequest_Video() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let otherUser = otherUser(moc: uiMOC)
        createOneOnOneConversation(user: otherUser)
        let conversation = otherUser.oneToOneConversation!
        uiMOC.saveOrRollback()

        // when
        sut.requestJoinCall(in: conversation, video: true)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXStartCallAction)
        let action = callKitController.requestedTransactions.first!.actions.first! as! CXStartCallAction

        XCTAssertEqual(action.callUUID, sut.callRegister.lookupCall(by: conversation)?.id)
        XCTAssertEqual(action.handle.type, .generic)
        XCTAssertEqual(
            action.handle.value,
            "\(selfUser.remoteIdentifier!.transportString())+\(conversation.remoteIdentifier!.transportString())"
        )
        XCTAssertTrue(action.isVideo)
    }

    func testThatItReportsTheStartCallRequest_CallAlreadyExists() {
        // given
        let otherUser = otherUser(moc: uiMOC)
        createOneOnOneConversation(user: otherUser)
        let conversation = otherUser.oneToOneConversation!
        uiMOC.saveOrRollback()

        callKitController.mockErrorCount = 1
        let error = NSError(
            domain: CXErrorDomainRequestTransaction,
            code: CXErrorCodeRequestTransactionError.Code.callUUIDAlreadyExists.rawValue,
            userInfo: nil
        )
        callKitController.mockTransactionErrorCode = CXErrorCodeRequestTransactionError(_nsError: error)

        // when
        sut.requestJoinCall(in: conversation, video: true)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 2)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXStartCallAction)
        XCTAssertTrue(callKitController.requestedTransactions.last!.actions.first! is CXAnswerCallAction)

        let action = callKitController.requestedTransactions.last!.actions.last! as! CXAnswerCallAction
        XCTAssertEqual(action.callUUID, sut.callRegister.lookupCall(by: conversation)?.id)
    }

    func testThatItReportsTheAnswerCallRequest_IfThereExistingIncomingCall() {
        // given
        let otherUser = otherUser(moc: uiMOC)
        createOneOnOneConversation(user: otherUser)
        let conversation = otherUser.oneToOneConversation!
        uiMOC.saveOrRollback()

        let state: CallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockWireCallCenterV3.setMockCallState(
            state,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: false
        )
        sut.callCenterDidChange(
            callState: state,
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(),
            previousCallState: nil
        )

        let call = CallKitDelegateTestsMocking.mockCall(
            with: sut.callRegister.lookupCall(by: conversation)!.id,
            outgoing: false
        )
        callKitController.mockCallObserver.mockCalls = [call]

        // when
        sut.requestJoinCall(in: conversation, video: true)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)

        let action = callKitController.requestedTransactions.last!.actions.last! as! CXAnswerCallAction
        XCTAssertEqual(action.callUUID, sut.callRegister.lookupCall(by: conversation)?.id)

        // teardown
        CallKitDelegateTestsMocking.stopMock(call)
    }

    // MARK: Performing Actions

    func testThatCallAnswerActionIsFulfilledWhenCallIsEstablished() throws {
        // given
        let otherUser = otherUser(moc: uiMOC)
        createOneOnOneConversation(user: otherUser)
        let conversation = otherUser.oneToOneConversation!
        let provider = MockProvider(foo: true)

        sut.reportIncomingCall(from: otherUser, in: conversation, hasVideo: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [
            callKitCall.handle: conversation,
        ]

        let action = MockCallAnswerAction(call: callKitCall.id)
        sut.provider(provider, perform: action)

        // when
        mockWireCallCenterV3.update(
            callState: .established,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: false
        )

        // then
        XCTAssertTrue(action.isFulfilled)
    }

    func testThatCallAnswerActionIsFulfilledWhenDataChannelIsEstablished() throws {
        // given
        let otherUser = otherUser(moc: uiMOC)
        createOneOnOneConversation(user: otherUser)
        let conversation = otherUser.oneToOneConversation!
        let provider = MockProvider(foo: true)

        sut.reportIncomingCall(from: otherUser, in: conversation, hasVideo: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [
            callKitCall.handle: conversation,
        ]

        let action = MockCallAnswerAction(call: callKitCall.id)
        sut.provider(provider, perform: action)

        // when
        mockWireCallCenterV3.update(
            callState: .establishedDataChannel,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: false
        )

        // then
        XCTAssertTrue(action.isFulfilled)
    }

    // Disabled for now, pending furter investigation
    // func testThatCallAnswerActionFailWhenCallCantBeJoined() {
    // // given
    // let otherUser = self.otherUser(moc: self.uiMOC)
    // let provider = MockProvider(foo: true)
    // let conversation = self.conversation(type: .oneOnOne)
    //
    // sut.reportIncomingCall(from: otherUser, in: conversation, video: false)
    // let action = MockCallAnswerAction(call: sut.callUUID(for: conversation)!)
    // self.sut.provider(provider, perform: action)
    //
    // // when
    // mockWireCallCenterV3.update(callState: .terminating(reason: .lostMedia), conversationId:
    // conversation.remoteIdentifier!, callerId: otherUser.remoteIdentifier, isVideo: false)
    // XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    // // then
    // XCTAssertTrue(action.hasFailed)
    // }

    func testThatStartCallActionIsFulfilledWhenCallIsJoined() {
        // given
        let provider = MockProvider(foo: true)
        let conversation = conversation(type: .oneOnOne)

        sut.requestStartCall(in: conversation, video: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [
            callKitCall.handle: conversation,
        ]

        let action = MockStartCallAction(
            call: callKitCall.id,
            handle: CXHandle(type: CXHandle.HandleType.generic, value: conversation.remoteIdentifier!.transportString())
        )

        // when
        sut.provider(provider, perform: action)

        // then
        XCTAssertTrue(action.isFulfilled)
    }

    func testThatStartCallActionFailWhenCallCantBeStarted() {
        // given
        let provider = MockProvider(foo: true)
        let conversation = conversation(type: .oneOnOne)

        sut.requestStartCall(in: conversation, video: false)
        let action = MockStartCallAction(
            call: sut.callRegister.lookupCall(by: conversation)!.id,
            handle: CXHandle(type: CXHandle.HandleType.generic, value: conversation.remoteIdentifier!.transportString())
        )
        mockWireCallCenterV3.startCallShouldFail = true

        // when
        sut.provider(provider, perform: action)

        // then
        XCTAssertTrue(action.hasFailed)
    }

    func testThatStartCallActionUpdatesWhenTheCallHasStartedConnecting() {
        // given
        let provider = MockProvider(foo: true)
        let conversation = conversation(type: .oneOnOne)

        sut.requestStartCall(in: conversation, video: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [
            callKitCall.handle: conversation,
        ]

        let action = MockStartCallAction(
            call: callKitCall.id,
            handle: CXHandle(type: CXHandle.HandleType.generic, value: conversation.remoteIdentifier!.transportString())
        )

        // when
        sut.provider(provider, perform: action)
        mockWireCallCenterV3.update(
            callState: .answered(degraded: false),
            conversationId: conversation.avsIdentifier!,
            callerId: ZMUser.selfUser(in: uiMOC).avsIdentifier,
            isVideo: false
        )

        // then
        XCTAssertTrue(provider.connectingCalls.contains(callKitCall.id))
    }

    func testThatStartCallActionUpdatesWhenTheCallHasConnected() {
        // given
        let provider = MockProvider(foo: true)
        let conversation = conversation(type: .oneOnOne)

        sut.requestStartCall(in: conversation, video: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [
            callKitCall.handle: conversation,
        ]

        let action = MockStartCallAction(
            call: callKitCall.id,
            handle: CXHandle(type: CXHandle.HandleType.generic, value: conversation.remoteIdentifier!.transportString())
        )

        // when
        sut.provider(provider, perform: action)
        mockWireCallCenterV3.update(
            callState: .establishedDataChannel,
            conversationId: conversation.avsIdentifier!,
            callerId: ZMUser.selfUser(in: uiMOC).avsIdentifier,
            isVideo: false
        )

        // then
        XCTAssertTrue(provider.connectedCalls.contains(callKitCall.id))
    }

    // MARK: Report end on outgoing call

    func testThatItReportsTheEndOfCall() {
        // given
        let conversation = conversation(type: .oneOnOne)
        let otherUser = otherUser(moc: uiMOC)

        let state: CallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockWireCallCenterV3.setMockCallState(
            state,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: true
        )
        sut.callCenterDidChange(
            callState: state,
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(),
            previousCallState: nil
        )
        guard let callUUID = sut.callRegister.lookupCall(by: conversation)?.id else {
            return XCTFail()
        }

        // when
        sut.requestEndCall(in: conversation)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXEndCallAction)

        let action = callKitController.requestedTransactions.first!.actions.first! as! CXEndCallAction
        XCTAssertEqual(action.callUUID, callUUID)
    }

    func testThatItReportsTheEndOfCall_groupConversation() {
        // given
        let conversation = conversation(type: .group)
        let otherUser = otherUser(moc: uiMOC)

        let state: CallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockWireCallCenterV3.setMockCallState(
            state,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: true
        )
        sut.callCenterDidChange(
            callState: state,
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(),
            previousCallState: nil
        )
        let callUUID = sut.callRegister.lookupCall(by: conversation)?.id

        // when
        sut.requestEndCall(in: conversation)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXEndCallAction)

        let action = callKitController.requestedTransactions.first!.actions.first! as! CXEndCallAction
        XCTAssertEqual(action.callUUID, callUUID)
    }

    func testThatReportsMutingOfCall() {
        // given
        let conversation = conversation(type: .group)
        let otherUser = otherUser(moc: uiMOC)

        let state: CallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockWireCallCenterV3.setMockCallState(
            state,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: true
        )
        sut.callCenterDidChange(
            callState: state,
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(),
            previousCallState: nil
        )
        let callUUID = sut.callRegister.lookupCall(by: conversation)?.id

        // when
        sut.requestMuteCall(in: conversation, muted: true)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXSetMutedCallAction)

        let action = callKitController.requestedTransactions.first!.actions.first! as! CXSetMutedCallAction
        XCTAssertEqual(action.callUUID, callUUID)
    }

    // MARK: Activity & Intents

    func userActivityFor(contacts: [INPerson], isVideo: Bool) -> NSUserActivity {
        let intent = INStartCallIntent(
            callRecordFilter: .none,
            callRecordToCallBack: .none,
            audioRoute: .speakerphoneAudioRoute,
            destinationType: .normal,
            contacts: contacts,
            callCapability: isVideo ? .videoCall : .audioCall
        )
        let interaction = INInteraction(intent: intent, response: .none)

        let activity = NSUserActivity(activityType: "voip")
        activity.setValue(interaction, forKey: "interaction")
        return activity
    }

    func testThatItStartsCallForGroup() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let conversation = conversation(type: .group)
        let identifier =
            "\(selfUser.remoteIdentifier!.transportString())+\(conversation.remoteIdentifier!.transportString())"
        let handle = INPersonHandle(value: identifier, type: .unknown)
        let person = INPerson(
            personHandle: handle,
            nameComponents: .none,
            displayName: .none,
            image: .none,
            contactIdentifier: .none,
            customIdentifier: identifier
        )
        let callHandle = WireSyncEngine.CallHandle(encodedString: identifier)!
        let activity = userActivityFor(contacts: [person], isVideo: false)

        mockCallKitManagerDelegate.mockConversations[callHandle] = conversation

        // when
        _ = sut.continueUserActivity(activity)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 1)
        XCTAssertTrue(callKitController.requestedTransactions.first!.actions.first! is CXStartCallAction)

        let action = callKitController.requestedTransactions.first!.actions.first! as! CXStartCallAction
        XCTAssertEqual(action.callUUID, sut.callRegister.lookupCall(by: conversation)?.id)
        XCTAssertFalse(action.isVideo)
    }

    func testThatItIgnoresUnknownActivity() {
        // given
        let activity = NSUserActivity(activityType: "random-handoff")

        // when
        _ = sut.continueUserActivity(activity)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 0)
    }

    func testThatItIgnoresActivityWitoutContacts() {
        // given
        let activity = userActivityFor(contacts: [], isVideo: false)

        // when
        _ = sut.continueUserActivity(activity)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 0)
    }

    func testThatItIgnoresActivityWithManyContacts() {
        // given

        let handle1 = INPersonHandle(value: "+987654321", type: .phoneNumber)
        let person1 = INPerson(
            personHandle: handle1,
            nameComponents: .none,
            displayName: .none,
            image: .none,
            contactIdentifier: .none,
            customIdentifier: .none
        )

        let handle2 = INPersonHandle(value: "+987654300", type: .phoneNumber)
        let person2 = INPerson(
            personHandle: handle2,
            nameComponents: .none,
            displayName: .none,
            image: .none,
            contactIdentifier: .none,
            customIdentifier: .none
        )

        let activity = userActivityFor(contacts: [person1, person2], isVideo: false)

        // when
        _ = sut.continueUserActivity(activity)

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 0)
    }

    func testThatItIgnoresActivityWithContactUnknown() {
        // given
        let otherUser = otherUser(moc: uiMOC)
        createOneOnOneConversation(user: otherUser)

        let handle = INPersonHandle(value: "+987654321", type: .phoneNumber)
        let person = INPerson(
            personHandle: handle,
            nameComponents: .none,
            displayName: .none,
            image: .none,
            contactIdentifier: .none,
            customIdentifier: .none
        )

        let activity = userActivityFor(contacts: [person], isVideo: false)

        // when
        performIgnoringZMLogError {
            _ = self.sut.continueUserActivity(activity)
        }

        // then
        XCTAssertEqual(callKitController.timesRequestTransactionCalled, 0)
    }

    // MARK: Observing call state

    func testThatItReportNewIncomingCall_v3_Incoming() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        // when
        sut.callCenterDidChange(
            callState: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.timesReportNewIncomingCallCalled, 1)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallConnectedAtCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallStartedConnectingCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportCallEndedAtCalled, 0)
    }

    func testThatItIgnoresNewIncomingCall_v3_Incoming_Silenced() {
        // given
        let conversation = conversation()
        conversation.mutedMessageTypes = .all
        let otherUser = otherUser(moc: uiMOC)

        // when
        sut.callCenterDidChange(
            callState: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.timesReportNewIncomingCallCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallConnectedAtCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallStartedConnectingCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportCallEndedAtCalled, 0)
    }

    func testThatItIgnoresNewIncomingCall_v3_Unfetched_conversation() {
        // given
        let conversation = conversation()
        conversation.needsToBeUpdatedFromBackend = true
        let otherUser = otherUser(moc: uiMOC)

        // when
        sut.callCenterDidChange(
            callState: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.timesReportNewIncomingCallCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallConnectedAtCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallStartedConnectingCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportCallEndedAtCalled, 0)
    }

    func testThatItIgnoresIncomingCall_IfItWasAlreadyReported() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        // report the call a first time
        sut.callCenterDidChange(
            callState: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // when
        sut.callCenterDidChange(
            callState: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        // we verify it was only reported once
        XCTAssertEqual(callKitProvider.timesReportNewIncomingCallCalled, 1)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallConnectedAtCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallStartedConnectingCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportCallEndedAtCalled, 0)
    }

    func testThatItReportCallEndedAt_v3_Terminating_normal() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)
        sut.requestStartCall(in: conversation, video: false)

        // when
        sut.callCenterDidChange(
            callState: .terminating(reason: .normal),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.timesReportNewIncomingCallCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallConnectedAtCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallStartedConnectingCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportCallEndedAtCalled, 1)
        XCTAssertEqual(callKitProvider.lastEndedReason, .remoteEnded)
    }

    func testThatItReportCallEndedAt_v3_Terminating_inTheFuture() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)
        sut.requestStartCall(in: conversation, video: false)

        // when
        sut.callCenterDidChange(
            callState: .terminating(reason: .normal),
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(timeIntervalSinceNow: 10000),
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.timesReportNewIncomingCallCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallConnectedAtCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallStartedConnectingCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportCallEndedAtCalled, 1)
        XCTAssertEqual(callKitProvider.lastEndedReason, .remoteEnded)
        XCTAssertEqual(Int(callKitProvider.lastEndedDate!.timeIntervalSinceNow), 0)
    }

    func testThatItReportCallEndedAt_v3_Terminating_lostMedia() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        let state: CallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockWireCallCenterV3.setMockCallState(
            state,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: true
        )
        sut.callCenterDidChange(
            callState: state,
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(),
            previousCallState: nil
        )

        // when
        sut.callCenterDidChange(
            callState: .terminating(reason: .lostMedia),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.lastEndedReason, .failed)
    }

    func testThatItReportCallEndedAt_v3_Terminating_timeout() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        let state: CallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockWireCallCenterV3.setMockCallState(
            state,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: true
        )
        sut.callCenterDidChange(
            callState: state,
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(),
            previousCallState: nil
        )

        // when
        sut.callCenterDidChange(
            callState: .terminating(reason: .timeout),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.lastEndedReason, .unanswered)
    }

    func testThatItReportCallEndedAt_v3_Terminating_answeredElsewhere() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        let state: CallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockWireCallCenterV3.setMockCallState(
            state,
            conversationId: conversation.avsIdentifier!,
            callerId: otherUser.avsIdentifier,
            isVideo: true
        )
        sut.callCenterDidChange(
            callState: state,
            conversation: conversation,
            caller: otherUser,
            timestamp: Date(),
            previousCallState: nil
        )

        // when
        sut.callCenterDidChange(
            callState: .terminating(reason: .answeredElsewhere),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.lastEndedReason, .answeredElsewhere)
    }

    // MARK: - Rejecting Calls

    func test_itProcessesCallEventsBeforeRejectingCall() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        sut.reportIncomingCall(from: otherUser, in: conversation, hasVideo: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        let mockEndCallAction = MockEndCallAction(call: callKitCall.id)

        // when
        sut.provider(callKitProvider, perform: mockEndCallAction)

        // then
        XCTAssertEqual(mockCallKitManagerDelegate.lookupConversationAndProcessPendingCallEventsCalls, 1)
    }

    func test_itUnregistersCallAfterRejecting() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        sut.reportIncomingCall(from: otherUser, in: conversation, hasVideo: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [
            callKitCall.handle: conversation,
        ]

        let mockEndCallAction = MockEndCallAction(call: callKitCall.id)

        // when
        sut.provider(callKitProvider, perform: mockEndCallAction)

        // then
        XCTAssertFalse(sut.callRegister.callExists(for: callKitCall.id))
    }

    func test_itUnregistersCallAfterRejecting_ConversationLookupFailed() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        sut.reportIncomingCall(from: otherUser, in: conversation, hasVideo: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [:]

        let mockEndCallAction = MockEndCallAction(call: callKitCall.id)

        // when
        sut.provider(callKitProvider, perform: mockEndCallAction)

        // then
        XCTAssertFalse(sut.callRegister.callExists(for: callKitCall.id))
    }

    func test_itIgnoresCallEnded_IfItWasAlreadyReported() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)
        sut.requestStartCall(in: conversation, video: false)

        // report the call is terminating a first time
        sut.callCenterDidChange(
            callState: .terminating(reason: .normal),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // when
        sut.callCenterDidChange(
            callState: .terminating(reason: .normal),
            conversation: conversation,
            caller: otherUser,
            timestamp: nil,
            previousCallState: nil
        )

        // then
        XCTAssertEqual(callKitProvider.timesReportNewIncomingCallCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallConnectedAtCalled, 0)
        XCTAssertEqual(callKitProvider.timesReportOutgoingCallStartedConnectingCalled, 0)
        // we verify that it was only reported once
        XCTAssertEqual(callKitProvider.timesReportCallEndedAtCalled, 1)
        XCTAssertEqual(callKitProvider.lastEndedReason, .remoteEnded)
    }

    // MARK: - Answering calls

    func test_itProcessesCallEventsBeforeAcceptingCall() {
        // given
        let conversation = conversation()
        let otherUser = otherUser(moc: uiMOC)

        sut.reportIncomingCall(from: otherUser, in: conversation, hasVideo: false)

        guard let callKitCall = sut.callRegister.lookupCall(by: conversation) else {
            XCTFail("no call handle")
            return
        }

        mockCallKitManagerDelegate.mockConversations = [
            callKitCall.handle: conversation,
        ]

        let mockAnswerCallAction = MockCallAnswerAction(call: callKitCall.id)

        // when
        sut.provider(callKitProvider, perform: mockAnswerCallAction)

        // then
        XCTAssertEqual(mockCallKitManagerDelegate.lookupConversationAndProcessPendingCallEventsCalls, 1)
    }
}
