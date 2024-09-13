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

import avs
import Combine
import Foundation

private let zmLog = ZMSLog(tag: "calling")

/// WireCallCenter is used for making Wire calls and observing their state. There can only be one instance of the
/// WireCallCenter.
///
/// Thread safety: WireCallCenter instance methods should only be called from the main thread, class method can be
/// called from any thread.
public class WireCallCenterV3: NSObject {
    static let logger = WireLogger.calling

    /// The maximum number of participants for a legacy video call.

    let legacyVideoParticipantsLimit = 4

    // MARK: - Properties

    /// The selfUser remoteIdentifier
    let selfUserId: AVSIdentifier

    /// The object that controls media flow.
    let flowManager: FlowManagerType

    /// The object to use to record stats about the call.
    let analytics: AnalyticsType?

    /// The bridge to use to communicate with and receive events from AVS.
    var avsWrapper: AVSWrapperType!

    /// The Core Data context to use to coordinate events.
    weak var uiMOC: NSManagedObjectContext?

    /// The object that performs network requests when the call center requests them.
    weak var transport: WireCallCenterTransport?

    // MARK: - Calling State

    /// The date when the call was established (Participants can talk to each other).
    /// - note: This property is only valid when the call state is `.established`.

    var establishedDate: Date?

    /// Whether we use constant bit rate for calls.
    /// - note: Changing this property after the call has started has no effect.

    var useConstantBitRateAudio = false

    var usePackagingFeatureConfig = false

    var isMuted: Bool {
        get { avsWrapper.isMuted }
        set { avsWrapper.isMuted = newValue }
    }

    /// The snaphot of the call state for each non-idle conversation.
    var callSnapshots: [AVSIdentifier: CallSnapshot] = [:]

    /// Used to collect incoming events (e.g. from fetching the notification stream) until AVS is ready to process them.
    var bufferedEvents: [(event: CallEvent, completionHandler: () -> Void)] = []

    /// Set to true once AVS calls the ReadyHandler. Setting it to `true` forwards all previously buffered events to
    /// AVS.
    var isReady = false {
        didSet {
            VoIPPushHelper.isAVSReady = isReady

            if isReady {
                for item in bufferedEvents {
                    let (event, completionHandler) = item
                    handleCallEvent(event, completionHandler: completionHandler)
                }
                bufferedEvents = []
            }
        }
    }

    /// Used to store AVS completions for the clients requests. AVS will only request the list of clients
    /// once, but we may need to provide AVS with an updated list during the call.
    var clientsRequestCompletionsByConversationId = [AVSIdentifier: (String) -> Void]()

    private let onParticipantsChangedSubject = PassthroughSubject<ConferenceParticipantsInfo, Never>()

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    private(set) var isEnabled = true

    // MARK: - Initialization

    deinit {
        avsWrapper.close()
    }

    /// Creates a call center with the required details.
    /// - parameter userId: The identifier of the current signed-in user.
    /// - parameter clientId: The identifier of the current client on the user's account.
    /// - parameter avsWrapper: The bridge to use to communicate with and receive events from AVS.
    /// If you don't specify one, a default object will be created. Defaults to `nil`.
    /// - parameter uiMOC: The Core Data context to use to coordinate events.
    /// - parameter flowManager: The object that controls media flow.
    /// - parameter analytics: The object to use to record stats about the call. Defaults to `nil`.
    /// - parameter transport: The object that performs network requests when the call center requests them.

    public required init(
        userId: AVSIdentifier,
        clientId: String,
        avsWrapper: AVSWrapperType? = nil,
        uiMOC: NSManagedObjectContext,
        flowManager: FlowManagerType,
        analytics: AnalyticsType? = nil,
        transport: WireCallCenterTransport
    ) {
        self.selfUserId = userId
        self.uiMOC = uiMOC
        self.flowManager = flowManager
        self.analytics = analytics
        self.transport = transport

        super.init()

        let observer = Unmanaged.passUnretained(self).toOpaque()
        self.avsWrapper = avsWrapper ?? AVSWrapper(userId: userId, clientId: clientId, observer: observer)
    }

    func tearDown() {
        isEnabled = false
    }
}

// MARK: - Snapshots

extension WireCallCenterV3 {
    /// Removes the participantSnapshot and remove the conversation from the list of ignored conversations.
    func clearSnapshot(conversationId: AVSIdentifier) {
        callSnapshots.removeValue(forKey: conversationId)
        clientsRequestCompletionsByConversationId.removeValue(forKey: conversationId)
    }

    /// Creates a snapshot for the specified call and adds it to the `callSnapshots` array.
    /// - parameter callState:
    /// - parameter members: The current members of the call.
    /// - parameters callStarter: The ID of the user that started the call.
    /// - parameter video: Whether the call is a video call.
    /// - parameter conversationId: The identifier of the conversation that hosts the call.

    func createSnapshot(
        callState: CallState,
        members: [AVSCallMember],
        callStarter: AVSIdentifier,
        video: Bool,
        for conversationId: AVSIdentifier,
        conversationType: AVSConversationType
    ) {
        guard
            let moc = uiMOC,
            let conversation = ZMConversation.fetch(
                with: conversationId.identifier,
                domain: conversationId.domain,
                in: moc
            )
        else {
            return
        }

        let callParticipants = CallParticipantsSnapshot(
            conversationId: conversationId,
            members: members,
            callCenter: self
        )
        let token = ConversationChangeInfo.add(observer: self, for: conversation)
        let group = conversation.conversationType == .group

        callSnapshots[conversationId] = CallSnapshot(
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: video,
            isGroup: group,
            isConstantBitRate: useConstantBitRateAudio,
            videoState: video ? .started : .stopped,
            networkQuality: .normal,
            conversationType: conversationType,
            degradedUser: nil,
            activeSpeakers: [],
            videoGridPresentationMode: .allVideoStreams,
            conversationObserverToken: token
        )
    }
}

// MARK: - State Helpers

extension WireCallCenterV3 {
    /// All non idle conversations and their corresponding call state.
    public var nonIdleCalls: [AVSIdentifier: CallState] {
        callSnapshots.mapValues { $0.callState }
    }

    /// The list of conversation with established calls.
    public var activeCalls: [AVSIdentifier: CallState] {
        nonIdleCalls.filter { _, callState in
            switch callState {
            case .established, .establishedDataChannel:
                true
            default:
                false
            }
        }
    }

    /// Checks the state of video calling in the conversation.
    /// - parameter conversationId: The identifier of the conversation to check the state of.
    /// - returns: Whether the conversation hosts a video call.

    public func isVideoCall(conversationId: AVSIdentifier) -> Bool {
        callSnapshots[conversationId]?.isVideo ?? false
    }

    /// Checks the call bitrate type used in the conversation.
    /// - parameter conversationId: The identifier of the conversation to check the state of.
    /// - returns: Whether the call is being made with a constant bitrate.

    public func isContantBitRate(conversationId: AVSIdentifier) -> Bool {
        callSnapshots[conversationId]?.isConstantBitRate ?? false
    }

    /// Determines the video state of the specified user in the conversation.
    /// - parameter conversationId: The identifier of the conversation to check the state of.
    /// - returns: The video-sending state of the user inside conversation.

    public func videoState(conversationId: AVSIdentifier) -> VideoState {
        callSnapshots[conversationId]?.videoState ?? .stopped
    }

    /// Determines the call state of the conversation.
    /// - parameter conversationId: The identifier of the conversation to check the state of.
    /// - returns: The state of calling of conversation, if any.

    public func callState(conversationId: AVSIdentifier) -> CallState {
        callSnapshots[conversationId]?.callState ?? .none
    }

    /// Determines the call state of the conversation.
    /// - parameter conversationId: The identifier of the conversation to check the state of.
    /// - returns: Whether there is an active call in the conversation.

    public func isActive(conversationId: AVSIdentifier) -> Bool {
        switch callState(conversationId: conversationId) {
        case .established, .establishedDataChannel:
            true
        default:
            false
        }
    }

    /// Determines the degradation of the conversation.
    /// - parameter conversationId: The identifier of the conversation to check the state of.
    /// - returns: Whether the conversation has degraded security or the call in the conversation has a degraded user.

    public func isDegraded(conversationId: AVSIdentifier) -> Bool {
        guard
            isEnabled,
            let uiMOC,
            let conversation = ZMConversation.fetch(
                with: conversationId.identifier,
                domain: conversationId.domain,
                in: uiMOC
            )
        else {
            return  false
        }
        let isConversationDegraded = conversation.isDegraded
        let isCallDegraded = callSnapshots[conversationId]?.isDegradedCall ?? false
        return isConversationDegraded || isCallDegraded
    }

    func canJoinCall(conversationId: AVSIdentifier) -> Bool {
        guard
            isEnabled,
            let context = uiMOC,
            let conversation = ZMConversation.fetch(
                with: conversationId.identifier,
                domain: conversationId.domain,
                in: context
            )
        else {
            return  false
        }

        return conversation.isSelfAnActiveMember && !conversation.isDeletedRemotely
    }

    /// Returns conversations with active calls.
    public func activeCallConversations(in userSession: ZMUserSession) -> [ZMConversation] {
        guard isEnabled else { return  [] }
        let conversations = nonIdleCalls.compactMap { (key: AVSIdentifier, value: CallState) -> ZMConversation? in
            switch value {
            case .establishedDataChannel, .established, .answered, .outgoing:
                return ZMConversation.fetch(
                    with: key.identifier,
                    domain: key.domain,
                    in: userSession.managedObjectContext
                )
            default:
                return nil
            }
        }

        return conversations
    }

    /// Returns conversations with a non idle call state.
    public func nonIdleCallConversations(in userSession: ZMUserSession) -> [ZMConversation] {
        let conversations = nonIdleCalls.compactMap { (key: AVSIdentifier, _: CallState) -> ZMConversation? in
            ZMConversation.fetch(
                with: key.identifier,
                domain: key.domain,
                in: userSession.managedObjectContext
            )
        }

        return conversations
    }

    public func networkQuality(conversationId: AVSIdentifier) -> NetworkQuality {
        callSnapshots[conversationId]?.networkQuality ?? .normal
    }

    public func isConferenceCall(conversationId: AVSIdentifier) -> Bool {
        callSnapshots[conversationId]?.conversationType.isConference ?? false
    }

    public func isMLSConferenceCall(conversationId: AVSIdentifier) -> Bool {
        callSnapshots[conversationId]?.conversationType == .mlsConference
    }

    func degradedUser(conversationId: AVSIdentifier) -> ZMUser? {
        callSnapshots[conversationId]?.degradedUser
    }

    public func videoGridPresentationMode(conversationId: AVSIdentifier) -> VideoGridPresentationMode {
        callSnapshots[conversationId]?.videoGridPresentationMode ?? .allVideoStreams
    }

    private func isGroup(conversationId: AVSIdentifier) -> Bool {
        callSnapshots[conversationId]?.isGroup ?? false
    }
}

// MARK: - Call Participants

extension WireCallCenterV3 {
    /// Get a list of callParticipants of a given kind for a conversation
    /// - Parameters:
    ///   - conversationId: the avs identifier of the conversation
    ///   - kind: the kind of participants expected in return
    ///   - activeSpeakersLimit: the limit of active speakers to be included
    /// - Returns: the callParticipants currently in the conversation, according to the specified kind
    func callParticipants(
        conversationId: AVSIdentifier,
        kind: CallParticipantsListKind,
        activeSpeakersLimit limit: Int? = nil
    ) -> [CallParticipant] {
        guard isEnabled else { return  [] }
        guard
            let callMembers = callSnapshots[conversationId]?.callParticipants.members.array,
            let context = uiMOC
        else {
            return []
        }

        let activeSpeakers = activeSpeakers(conversationId: conversationId, limitedBy: limit)

        return callMembers.compactMap { member in
            var activeSpeakerState: ActiveSpeakerState = .inactive

            if let activeSpeaker = activeSpeakers.first(where: { $0.client == member.client }) {
                activeSpeakerState = kind.state(ofActiveSpeaker: activeSpeaker)
            }

            if kind == .smoothedActiveSpeakers, activeSpeakerState == .inactive {
                return nil
            }

            return CallParticipant(member: member, activeSpeakerState: activeSpeakerState, context: context)
        }
    }

    private func activeSpeakers(
        conversationId: AVSIdentifier,
        limitedBy limit: Int? = nil
    ) -> [AVSActiveSpeakersChange.ActiveSpeaker] {
        guard isEnabled else { return [] }
        guard let activeSpeakers = callSnapshots[conversationId]?.activeSpeakers else {
            return []
        }

        guard let limit else {
            return activeSpeakers
        }

        return Array(activeSpeakers.prefix(limit))
    }

    /// Returns the remote identifier of the user that initiated the call.
    func initiatorForCall(conversationId: AVSIdentifier) -> AVSIdentifier? {
        guard isEnabled else { return nil }
        return callSnapshots[conversationId]?.callStarter
    }

    /// Call this method when the callParticipants changed and avs calls the handler `wcall_participant_changed_h`
    func callParticipantsChanged(conversationId: AVSIdentifier, participants: [AVSCallMember]) {
        guard isEnabled else { return }
        let shouldEndCall = shouldEndCall(
            conversationId: conversationId,
            previousParticipants: callSnapshots[conversationId]?.callParticipants.members.array ?? [],
            newParticipants: participants
        )
        guard !shouldEndCall else {
            endAllCalls()
            return
        }

        callSnapshots[conversationId]?.callParticipants.callParticipantsChanged(participants: participants)

        if let participants = callSnapshots[conversationId]?.callParticipants.participants {
            onParticipantsChangedSubject.send(
                ConferenceParticipantsInfo(
                    participants: participants,
                    selfUserID: selfUserId
                )
            )
        }
    }

    func onParticipantsChanged() -> AnyPublisher<ConferenceParticipantsInfo, Never> {
        onParticipantsChangedSubject.eraseToAnyPublisher()
    }
}

// MARK: - Call ending for oneOnOne conversations

extension WireCallCenterV3 {
    /// We treat 1:1 calls as conferences (via SFT) if `useSFTForOneToOneCalls` from the `conferenceCalling` feature is
    /// `true`.
    /// If the other user hangs up, we should end the call for the self user.
    /// More info (Option 1):
    /// https://wearezeta.atlassian.net/wiki/spaces/PAD/pages/1314750477/2024-07-29+1+1+calls+over+SFT
    private func shouldEndCall(
        conversationId: AVSIdentifier,
        previousParticipants: [AVSCallMember],
        newParticipants: [AVSCallMember]
    ) -> Bool {
        guard let context = uiMOC,
              let conversation = ZMConversation.fetch(
                  with: conversationId.identifier,
                  domain: conversationId.domain,
                  in: context
              ),
              conversation.conversationType == .oneOnOne,
              callSnapshots[conversationId]?.callState == .established
        else {
            return false
        }

        switch conversation.messageProtocol {
        case .mls:
            return shouldEndCallForMLS(
                previousParticipants: previousParticipants,
                newParticipants: newParticipants
            )
        case .mixed, .proteus:
            return shouldEndCallForProteus(
                previousParticipants: previousParticipants,
                newParticipants: newParticipants
            )
        }
    }

    private func shouldEndCallForMLS(
        previousParticipants: [AVSCallMember],
        newParticipants: [AVSCallMember]
    ) -> Bool {
        /// We assume that the 2nd participant is the other user, and if the other user's audio state is connecting, the
        /// call should end.
        guard
            previousParticipants.count == 2,
            newParticipants.count == 2,
            newParticipants[1].audioState == .connecting
        else {
            return false
        }
        return true
    }

    private func shouldEndCallForProteus(
        previousParticipants: [AVSCallMember],
        newParticipants: [AVSCallMember]
    ) -> Bool {
        previousParticipants.count == 2 && newParticipants.count == 1
    }
}

// MARK: - Actions

extension WireCallCenterV3 {
    public enum Failure: Error {
        case missingAVSIdentifier
        case missingAVSConversationType
        case missingConferencingPermission
        case failedToSetupMLSConference
        case unknown
    }

    /// Answers an incoming call in the given conversation.
    ///
    /// - Parameters:
    ///  - conversation: The conversation hosting the incoming call.
    ///  - video: Whether to join the call with video.
    ///
    /// - Throws: WireCallCenterV3.Failure

    public func answerCall(
        conversation: ZMConversation,
        video: Bool
    ) throws {
        Self.logger.info("answering call")

        guard let conversationId = conversation.avsIdentifier else {
            throw Failure.missingAVSIdentifier
        }

        endAllCalls(exluding: conversationId)

        let callType = callType(
            for: conversation,
            startedWithVideo: video,
            isConferenceCall: isConferenceCall(conversationId: conversationId)
        )

        let answered = avsWrapper.answerCall(
            conversationId: conversationId,
            callType: callType,
            useCBR: useConstantBitRateAudio
        )

        guard answered else {
            throw Failure.unknown
        }

        let callState: CallState = .answered(degraded: isDegraded(conversationId: conversationId))

        let previousSnapshot = callSnapshots[conversationId]

        if previousSnapshot != nil {
            callSnapshots[conversationId] = previousSnapshot!.update(with: callState)
        }

        if let context = uiMOC, let callerId = initiatorForCall(conversationId: conversationId) {
            WireCallCenterCallStateNotification(
                context: context,
                callState: callState,
                conversationId: conversationId,
                callerId: callerId,
                messageTime: nil,
                previousCallState: previousSnapshot?.callState
            ).post(in: context.notificationContext)
        }

        switch conversation.messageProtocol {
        case .proteus, .mixed:
            break

        case .mls:
            guard
                let conversationType = getAVSConversationType(for: conversation),
                conversationType == .mlsConference
            else {
                return
            }
            try setUpMLSConference(in: conversation)
        }
    }

    /// Starts a call in the given conversation.
    ///
    /// - Parameters:
    ///   - conversation: The conversation to start the call.
    ///   - isVideo: Whether to start the call as a video call.
    ///
    /// - Throws: WireCallCenterV3.Failure

    public func startCall(in conversation: ZMConversation, isVideo: Bool) throws {
        Self.logger.info("starting call")

        guard let conversationId = conversation.avsIdentifier else {
            throw Failure.missingAVSIdentifier
        }

        endAllCalls(exluding: conversationId)

        // Make sure we don't have an old state for this conversation.
        clearSnapshot(conversationId: conversationId)

        guard let conversationType = getAVSConversationType(for: conversation) else {
            throw Failure.missingAVSConversationType
        }

        let callType = callType(
            for: conversation,
            startedWithVideo: isVideo,
            isConferenceCall: conversationType.isConference
        )

        if conversationType.isConference, !canStartConferenceCalls {
            if let context = uiMOC {
                WireCallCenterConferenceCallingUnavailableNotification().post(in: context.notificationContext)
            }

            throw Failure.missingConferencingPermission
        }

        let started = avsWrapper.startCall(
            conversationId: conversationId,
            callType: callType,
            conversationType: conversationType,
            useCBR: useConstantBitRateAudio
        )

        guard started else {
            throw Failure.unknown
        }

        let callState: CallState = .outgoing(degraded: isDegraded(conversationId: conversationId))
        let previousCallState = callSnapshots[conversationId]?.callState

        createSnapshot(
            callState: callState,
            members: [],
            callStarter: selfUserId,
            video: isVideo,
            for: conversationId,
            conversationType: conversationType
        )

        if let context = uiMOC {
            WireCallCenterCallStateNotification(
                context: context,
                callState: callState,
                conversationId: conversationId,
                callerId: selfUserId,
                messageTime: nil,
                previousCallState: previousCallState
            ).post(in: context.notificationContext)
        }

        switch conversation.messageProtocol {
        case .proteus, .mixed:
            break
        case .mls:
            guard conversationType == .mlsConference else { return }
            try setUpMLSConference(in: conversation)
        }
    }

    private var canStartConferenceCalls: Bool {
        guard usePackagingFeatureConfig else {
            return true
        }
        guard let context = uiMOC else { return false }
        let conferenceCalling = FeatureRepository(context: context).fetchConferenceCalling()
        return conferenceCalling.status == .enabled
    }

    /// Sets up the MLS conference for a given conversation.
    ///
    /// - Parameter conversation: The conversation to set up the MLS conference for.
    ///
    /// See documentation:
    /// https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/692027483/Use+case+Join+conference+sub-conversation+MLS

    private func setUpMLSConference(in conversation: ZMConversation) throws {
        guard let conversationID = conversation.avsIdentifier else {
            throw Failure.failedToSetupMLSConference
        }

        guard
            let parentQualifiedID = conversation.qualifiedID,
            let parentGroupID = conversation.mlsGroupID,
            let syncContext = conversation.managedObjectContext?.zm_sync
        else {
            onMLSConferenceFailure(id: conversationID)
            throw Failure.failedToSetupMLSConference
        }

        syncContext.perform { [weak self] in
            guard
                let self,
                let mlsService = syncContext.mlsService
            else {
                self?.onMLSConferenceFailure(id: conversationID)
                return
            }

            Task {
                do {
                    // Join the subgroup or create it if it doesn't exist
                    let subgroupID = try await mlsService.createOrJoinSubgroup(
                        parentQualifiedID: parentQualifiedID,
                        parentID: parentGroupID
                    )

                    // Generate and set the conference information for the subgroup
                    let initialConferenceInfo = try await mlsService.generateConferenceInfo(
                        parentGroupID: parentGroupID,
                        subconversationGroupID: subgroupID
                    )

                    self.avsWrapper.setMLSConferenceInfo(
                        conversationId: conversationID,
                        info: initialConferenceInfo
                    )

                    // Set up a task to observe changes in the conference information
                    // and update AVS accordingly
                    let updateConferenceInfoTask = Task {
                        let onConferenceInfoChange = mlsService.onConferenceInfoChange(
                            parentGroupID: parentGroupID,
                            subConversationGroupID: subgroupID
                        )

                        do {
                            for try await conferenceInfo in onConferenceInfoChange {
                                try Task.checkCancellation()
                                self.avsWrapper.setMLSConferenceInfo(
                                    conversationId: conversationID,
                                    info: conferenceInfo
                                )
                            }
                        } catch {
                            WireLogger.calling.error("Error updating conference info: \(error)")
                        }
                    }

                    // Create the stale participants remover
                    // and subscribe to the publisher of participants changes
                    let staleParticipantsRemover = MLSConferenceStaleParticipantsRemover(
                        mlsService: mlsService,
                        syncContext: syncContext
                    )

                    self.onMLSConferenceParticipantsChanged(
                        subconversationID: subgroupID
                    ).subscribe(staleParticipantsRemover)

                    // Set up the call snapshot
                    if var snapshot = self.callSnapshots[conversationID] {
                        snapshot.qualifiedID = parentQualifiedID
                        snapshot.groupIDs = (parentGroupID, subgroupID)
                        snapshot.updateConferenceInfoTask = updateConferenceInfoTask
                        snapshot.mlsConferenceStaleParticipantsRemover = staleParticipantsRemover
                        self.callSnapshots[conversationID] = snapshot
                    }
                } catch {
                    Self.logger.error("failed to set up MLS conference: \(String(describing: error))")
                    self.onMLSConferenceFailure(id: conversationID)
                    assertionFailure(String(reflecting: error))
                }
            }
        }
    }

    private func onMLSConferenceFailure(id: AVSIdentifier) {
        uiMOC?.perform { [weak self] in
            self?.closeCall(conversationId: id, reason: .unknown)
        }
    }

    /// Closes the call in the specified conversation.
    /// - parameter conversationId: The ID of the conversation where the call should be ended.
    /// - parameter reason: The reason why the call should be ended. The default is `.normal` (user action).

    public func closeCall(conversationId: AVSIdentifier, reason: CallClosedReason = .normal) {
        Self.logger.info("closing call")
        avsWrapper.endCall(conversationId: conversationId)

        if let previousSnapshot = callSnapshots[conversationId] {
            if previousSnapshot.isGroup {
                let callState: CallState = .incoming(
                    video: previousSnapshot.isVideo,
                    shouldRing: false,
                    degraded: isDegraded(conversationId: conversationId)
                )
                callSnapshots[conversationId] = previousSnapshot.update(with: callState)
            } else {
                callSnapshots[conversationId] = previousSnapshot.update(with: .terminating(reason: reason))
            }
        }

        if let mlsParentIDs = mlsParentIDS(for: conversationId) {
            var snapshot = callSnapshots[conversationId]
            snapshot?.updateConferenceInfoTask?.cancel()
            snapshot?.updateConferenceInfoTask = nil
            cancelPendingStaleParticipantsRemovals(callSnapshot: snapshot)
            snapshot?.mlsConferenceStaleParticipantsRemover?.stopSubscribing()
            snapshot?.mlsConferenceStaleParticipantsRemover = nil

            guard let viewContext = uiMOC,
                  let conversation = ZMConversation.fetch(
                      with: mlsParentIDs.qualifiedID.uuid,
                      domain: mlsParentIDs.qualifiedID.domain,
                      in: viewContext
                  ),
                  conversation.conversationType == .group
            else {
                deleteSubconversation(conversationID: conversationId)
                return
            }

            leaveSubconversation(
                parentQualifiedID: mlsParentIDs.0,
                parentGroupID: mlsParentIDs.1
            )
        }
    }

    /// Rejects an incoming call in the conversation.
    /// - parameter conversationId: The ID of the conversation where the incoming call is hosted.

    public func rejectCall(conversationId: AVSIdentifier) {
        Self.logger.info("rejecting call")
        avsWrapper.rejectCall(conversationId: conversationId)

        if let previousSnapshot = callSnapshots[conversationId] {
            let callState: CallState = .incoming(
                video: previousSnapshot.isVideo,
                shouldRing: false,
                degraded: isDegraded(conversationId: conversationId)
            )
            callSnapshots[conversationId] = previousSnapshot.update(with: callState)
        }
    }

    /// Ends all the calls. You can specify the identifier of a conversation where the call shouldn't be ended.
    /// - parameter excluding: If you need to terminate all calls except one, pass the identifier of the conversation
    /// that hosts the call to keep alive. If you pass `nil`, all calls will be ended. Defaults to `nil`.

    public func endAllCalls(exluding: AVSIdentifier? = nil) {
        Self.logger.info("ending all calls")
        nonIdleCalls.forEach { (key: AVSIdentifier, callState: CallState) in
            guard exluding == nil || key != exluding else { return }

            switch callState {
            case .incoming:
                rejectCall(conversationId: key)
            default:
                closeCall(conversationId: key)
            }
        }
    }

    /// Enables or disables video for a call.
    /// - parameter conversationId: The identifier of the conversation where the video call is hosted.
    /// - parameter videoState: The new video state for the self user.

    public func setVideoState(conversationId: AVSIdentifier, videoState: VideoState) {
        Self.logger.info("setting video state")
        guard videoState != .badConnection else { return }

        if let snapshot = callSnapshots[conversationId] {
            callSnapshots[conversationId] = snapshot.updateVideoState(videoState)
        }

        avsWrapper.setVideoState(conversationId: conversationId, videoState: videoState)
    }

    /// Sets the capture device type to use for video.
    /// - parameter captureDevice: The device type to use to capture video for the call.
    /// - parameter conversationId: The identifier of the conversation where the video call is hosted.

    public func setVideoCaptureDevice(_ captureDevice: CaptureDevice, for conversationId: AVSIdentifier) {
        flowManager.setVideoCaptureDevice(captureDevice, for: conversationId)
    }

    public func setVideoGridPresentationMode(
        _ presentationMode: VideoGridPresentationMode,
        for conversationId: AVSIdentifier
    ) {
        if let snapshot = callSnapshots[conversationId] {
            callSnapshots[conversationId] = snapshot.updateVideoGridPresentationMode(presentationMode)
        }
    }

    /// Requests AVS to load video streams for the given clients list
    /// - Parameters:
    ///   - conversationId: The identifier of the conversation where the video call is hosted.
    ///   - clients: The list of clients for which AVS should load video streams.
    public func requestVideoStreams(conversationId: AVSIdentifier, clients: [AVSClient]) {
        let videoStreams = AVSVideoStreams(conversationId: conversationId.serialized, clients: clients)
        avsWrapper.requestVideoStreams(videoStreams, conversationId: conversationId)
    }

    private func callType(
        for conversation: ZMConversation,
        startedWithVideo: Bool,
        isConferenceCall: Bool
    ) -> AVSCallType {
        if !isConferenceCall, conversation.localParticipants.count > legacyVideoParticipantsLimit {
            .audioOnly
        } else {
            startedWithVideo ? .video : .normal
        }
    }
}

// MARK: - AVS Integration

extension WireCallCenterV3 {
    /// Sends a call OTR message when requested by AVS through `wcall_send_h`.
    func send(
        token: WireCallMessageToken,
        conversationId: AVSIdentifier,
        targets: AVSClientList?,
        data: Data,
        dataLength: Int,
        overMLSSelfConversation: Bool = false
    ) {
        Self.logger.info("sending call message for AVS")
        zmLog.debug("\(self): send call message, transport = \(String(describing: transport))")
        transport?.send(
            data: data,
            conversationId: conversationId,
            targets: targets.map(\.clients),
            overMLSSelfConversation: overMLSSelfConversation,
            completionHandler: { [weak self] status in
                self?.avsWrapper.handleResponse(httpStatus: status, reason: "", context: token)
            }
        )
    }

    /// Sends an SFT call message when requested by AVS through `wcall_sft_req_h`.
    func sendSFT(token: WireCallMessageToken, url: String, data: Data) {
        Self.logger.info("sending SFT message for AVS")
        zmLog.debug("\(self): send SFT call message, transport = \(String(describing: transport))")

        guard let endpoint = URL(string: url) else {
            zmLog.error("SFT request failed. Invalid url: \(url)")
            avsWrapper.handleSFTResponse(data: nil, context: token)
            return
        }

        transport?.sendSFT(data: data, url: endpoint) { [weak self] result in
            switch result {
            case let .failure(error):
                zmLog.error("SFT request failed: \(error.localizedDescription)")
                self?.avsWrapper.handleSFTResponse(data: nil, context: token)

            case let .success(data):
                self?.avsWrapper.handleSFTResponse(data: data, context: token)
            }
        }
    }

    /// Sends the config request when requested by AVS through `wcall_config_req_h`.
    func requestCallConfig() {
        zmLog.debug("\(self): requestCallConfig(), transport = \(String(describing: transport))")
        transport?.requestCallConfig(completionHandler: { [weak self] config, httpStatusCode in
            guard let self else { return }
            zmLog.debug("\(self): self.avsWrapper.update with \(String(describing: config))")
            avsWrapper.update(callConfig: config, httpStatusCode: httpStatusCode)
        })
    }

    /// Tags a call as missing when requested by AVS through `wcall_missed_h`.
    func missed(conversationId: AVSIdentifier, userId: AVSIdentifier, timestamp: Date, isVideoCall: Bool) {
        zmLog.debug("missed call")

        if let context = uiMOC {
            WireCallCenterMissedCallNotification(
                context: context,
                conversationId: conversationId,
                callerId: userId,
                timestamp: timestamp,
                video: isVideoCall
            ).post(in: context.notificationContext)
        }

        updateMLSConferenceIfNeededForMissedCall(conversationID: conversationId)
    }

    /// Handles incoming OTR calling messages, and transmist them to AVS when it is ready to process events, or adds it
    /// to the `bufferedEvents`.
    /// - parameter callEvent: calling event to process.
    /// - parameter completionHandler: called after the call event has been processed (this will for example wait for
    /// AVS to signal that it's ready).
    func processCallEvent(_ callEvent: CallEvent, completionHandler: @escaping () -> Void) {
        Self.logger.info("process call event")
        if isReady {
            handleCallEvent(callEvent, completionHandler: completionHandler)
        } else {
            bufferedEvents.append((callEvent, completionHandler))
        }
    }

    private func handleCallEvent(
        _ callEvent: CallEvent,
        completionHandler: @escaping () -> Void
    ) {
        Self.logger.info("handle call event (timestamp: \(callEvent.currentTimestamp))")

        guard
            let context = uiMOC,
            let conversationType = conversationType(from: callEvent)
        else {
            Self.logger.warn("can't handle call event: unable to determine conversation type")
            completionHandler()
            return
        }

        let result = avsWrapper.received(
            callEvent: callEvent,
            conversationType: conversationType
        )

        if let error = result {
            WireCallCenterCallErrorNotification(
                context: context,
                error: error,
                conversationId: callEvent.conversationId
            ).post(in: context.notificationContext)
        }

        completionHandler()
    }

    private func conversationType(from callEvent: CallEvent) -> AVSConversationType? {
        conversationType(from: callEvent.conversationId)
    }

    func conversationType(from conversationId: AVSIdentifier) -> AVSConversationType? {
        guard let context = uiMOC else { return nil }

        var conversationType: AVSConversationType?

        context.performAndWait {
            if let conversation = ZMConversation.fetch(
                with: conversationId.identifier,
                domain: conversationId.domain,
                in: context
            ) {
                conversationType = getAVSConversationType(for: conversation)
            }
        }

        return conversationType
    }

    /// Handles a change in calling state.
    ///
    /// - Parameters:
    ///     - callState: The state to handle.
    ///     - conversationId: The id of the conversation where teh calling state has changed.
    ///     - messageTime: The timestamp of the event.

    func handle(
        callState: CallState,
        conversationId: AVSIdentifier,
        messageTime: Date? = nil,
        userId: AVSIdentifier? = nil
    ) {
        callState.logState()

        var callState = callState

        if case .terminating(reason: .stillOngoing) = callState {
            if isDegraded(conversationId: conversationId) {
                callState = .terminating(reason: .securityDegraded)
            } else if canJoinCall(conversationId: conversationId) {
                callState = .incoming(video: false, shouldRing: false, degraded: false)
            }
        }

        if case .incoming = callState, isGroup(conversationId: conversationId), activeCalls.isEmpty {
            isMuted = true
        }

        let callerId = initiatorForCall(conversationId: conversationId) ?? userId
        let previousCallState = callSnapshots[conversationId]?.callState

        if let previousSnapshot = callSnapshots[conversationId] {
            callSnapshots[conversationId] = previousSnapshot.update(with: callState)
        }

        updateMLSConferenceIfNeeded(
            conversationID: conversationId,
            callState: callState,
            callSnapshot: callSnapshots[conversationId]
        )

        if case .terminating = callState {
            clearSnapshot(conversationId: conversationId)
        }

        if let context = uiMOC, let callerId {
            let notification = WireCallCenterCallStateNotification(
                context: context,
                callState: callState,
                conversationId: conversationId,
                callerId: callerId,
                messageTime: messageTime,
                previousCallState: previousCallState
            )
            notification.post(in: context.notificationContext)
        }
    }
}

// MARK: - Get AVS conversation type

extension WireCallCenterV3 {
    private func getAVSConversationType(for conversation: ZMConversation) -> AVSConversationType? {
        switch (conversation.conversationType, conversation.messageProtocol) {
        case (.oneOnOne, _):
            getAVSConversationTypeForOneOnOne(conversation)

        case (.group, .proteus), (.group, .mixed):
            .conference

        case (.group, .mls), (.`self`, .mls):
            .mlsConference

        default:
            nil
        }
    }

    private func getAVSConversationTypeForOneOnOne(_ conversation: ZMConversation) -> AVSConversationType {
        guard
            let context = conversation.managedObjectContext,
            let featureConfig = FeatureRepository(context: context).fetchConferenceCalling().config,
            featureConfig.useSFTForOneToOneCalls
        else {
            return .oneToOne
        }

        switch conversation.messageProtocol {
        case .mls:
            return .mlsConference
        case .proteus, .mixed:
            return .conference
        }
    }
}
