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

import WireCommonComponents
import WireSyncEngine

struct CallGridConfiguration: CallGridViewControllerInput, Equatable {
    fileprivate static let maxActiveSpeakers = 4

    let floatingStream: Stream?
    let streams: [Stream]
    let videoState: VideoState
    let shouldShowActiveSpeakerFrame: Bool
    let presentationMode: VideoGridPresentationMode
    let callHasTwoParticipants: Bool
    let isConnected: Bool
    let isGroupCall: Bool

    init(voiceChannel: VoiceChannel) {
        let videoStreamArrangment = voiceChannel.createStreamArrangment()

        self.floatingStream = videoStreamArrangment.preview
        self.streams = videoStreamArrangment.grid
        self.videoState = voiceChannel.videoState
        self.shouldShowActiveSpeakerFrame = voiceChannel.shouldShowActiveSpeakerFrame
        self.presentationMode = voiceChannel.videoGridPresentationMode
        self.callHasTwoParticipants = voiceChannel.callHasTwoParticipants
        self.isConnected = voiceChannel.state.isConnected
        self.isGroupCall = voiceChannel.isGroupCall
    }
}

extension CallParticipant {
    var streamId: AVSClient {
        AVSClient(userId: userId, clientId: clientId)
    }
}

extension VoiceChannel {
    // MARK: - Stream Arrangment

    typealias StreamArrangment = (preview: Stream?, grid: [Stream])

    fileprivate func createStreamArrangment() -> StreamArrangment {
        guard isEstablished else { return streamArrangementForNonEstablishedCall }

        let participants = participants(forPresentationMode: videoGridPresentationMode)

        var streams = activeStreams(from: participants)

        if case let .limit(amount: amount) = callingConfig.streamLimit {
            streams = Array(streams.prefix(amount))
        }

        let selfStream = selfStream(
            from: streams,
            createIfNeeded: videoGridPresentationMode.needsSelfStream
        )

        return arrangeStreams(for: selfStream, participantsStreams: streams)
    }

    func arrangeStreams(for selfStream: Stream?, participantsStreams: [Stream]) -> StreamArrangment {
        let streamsExcludingSelf = participantsStreams.filter { $0.streamId != selfStreamId }
        let sortedStreamsList = sortByVideo(streamData: streamsExcludingSelf)
        guard let selfStream else {
            return (nil, sortedStreamsList)
        }
        if callHasTwoParticipants, sortedStreamsList.count == 1 {
            return (selfStream, sortedStreamsList)
        } else {
            return (nil, [selfStream] + sortedStreamsList)
        }
    }

    func sortByVideo(streamData: [Stream]) -> [Stream] {
        let sortedData = streamData.sorted {
            guard let videoStatusArgument0 = $0.videoState?.isSending else { return false }
            guard let videoStatusArgument1 = $1.videoState?.isSending else { return false }
            return videoStatusArgument0 && !videoStatusArgument1
        }
        return sortedData
    }

    private var streamArrangementForNonEstablishedCall: StreamArrangment {
        guard videoGridPresentationMode.needsSelfStream, let stream = createSelfStream() else {
            return (nil, [])
        }
        return (nil, [stream])
    }

    func participants(forPresentationMode mode: VideoGridPresentationMode) -> [CallParticipant] {
        var participants = participants(
            ofKind: mode.callParticipantsListKind,
            activeSpeakersLimit: CallGridConfiguration.maxActiveSpeakers
        )

        if mode == .allVideoStreams {
            participants.sortByName(selfStreamId: selfStreamId)
        }

        return participants
    }

    func activeStreams(from participants: [CallParticipant]) -> [Stream] {
        participants.compactMap { participant in
            Stream(
                streamId: participant.streamId,
                user: participant.user,
                callParticipantState: participant.state,
                activeSpeakerState: participant.activeSpeakerState,
                isPaused: participant.state.videoState?.isPaused ?? false
            )
        }
    }

    // MARK: - Self Stream

    private func createSelfStream() -> Stream? {
        guard
            let selfUser = ZMUser.selfUser(),
            let clientId = selfUser.selfClient()?.remoteIdentifier
        else {
            return nil
        }

        var isPaused = false
        switch (isUnconnectedOutgoingVideoCall, videoState) {
        case (true, _), (_, .started), (_, .badConnection), (_, .screenSharing):
            isPaused = false
        case (_, .paused):
            isPaused = true
        case (_, .stopped):
            return nil
        }

        return Stream(
            streamId: AVSClient(userId: selfUser.avsIdentifier, clientId: clientId),
            user: selfUser,
            callParticipantState: .connected(
                videoState: videoState,
                microphoneState: .unmuted
            ),
            activeSpeakerState: .inactive,
            isPaused: isPaused
        )
    }

    private var selfStreamId: AVSClient? {
        ZMUser.selfUser()?.selfStreamId
    }

    private func selfStream(from streams: [Stream], createIfNeeded: Bool) -> Stream? {
        guard let selfStream = streams.first(where: { $0.streamId == selfStreamId }) else {
            return createIfNeeded ? createSelfStream() : nil
        }

        return selfStream
    }

    // MARK: - Helpers

    private var callingConfig: CallingConfiguration { .config }

    private var isEstablished: Bool {
        state == .established
    }

    fileprivate var callHasTwoParticipants: Bool {
        participants.count == 2
    }

    fileprivate var shouldShowActiveSpeakerFrame: Bool {
        participants.count > 2 && videoGridPresentationMode == .allVideoStreams
    }

    private var isUnconnectedOutgoingVideoCall: Bool {
        switch (state, isVideoCall) {
        case (.outgoing, true): true
        default: false
        }
    }
}

extension VideoGridPresentationMode {
    fileprivate var callParticipantsListKind: CallParticipantsListKind {
        switch self {
        case .activeSpeakers:
            .smoothedActiveSpeakers
        case .allVideoStreams:
            .all
        }
    }

    fileprivate var needsSelfStream: Bool {
        self == .allVideoStreams
    }
}
