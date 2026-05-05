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

import UIKit
import class WireCommonComponents.NetworkStatus
import WireDataModel
import WireSyncEngine

// TODO: [WPB-9864]: Most of this code shouldn't be nested within `ZMConversation`.
extension ZMConversation {

    var isCallingSupported: Bool {
        localParticipants.count > 1
    }

    var firstCallingParticipantOtherThanSelf: UserType? {
        let participant = voiceChannel?.participants.first { !$0.user.isSelfUser }
        return participant?.user
    }

    func startAudioCall() {
        if warnAboutNoInternetConnection() {
            return
        }

        joinVoiceChannel(video: false)
    }

    func joinCall() {
        print("🔵 [JOINVCHANNEL] ZMConversation.joinCall() called for: \(remoteIdentifier?.uuidString ?? "unknown")")
        if conversationType == .group {
            voiceChannel?.muted = true
        }
        joinVoiceChannel(video: false)
    }

    func joinVoiceChannel(video: Bool) {
        print("🔵 [JOINVCHANNEL] joinVoiceChannel called with video: \(video)")
        guard let userSession = ZMUserSession.shared() else {
            print("🔵 [JOINVCHANNEL] No user session")
            return
        }

        let onGranted: (_ granted: Bool) -> Void = { granted in
            print("🔵 [JOINVCHANNEL] Permissions granted: \(granted)")
            if granted {
                print("🔵 [JOINVCHANNEL] Calling voiceChannel.join()")
                let result = self.voiceChannel?.join(video: video, userSession: userSession)
                print("🔵 [JOINVCHANNEL] voiceChannel.join() returned: \(result ?? false)")
            } else {
                print("🔵 [JOINVCHANNEL] Permission denied - leaving")
                self.voiceChannel?.leave(userSession: userSession, completion: nil)
            }
        }

        print("🔵 [JOINVCHANNEL] Requesting microphone access")
        UIApplication.wr_requestOrWarnAboutMicrophoneAccess { granted in
            print("🔵 [JOINVCHANNEL] Microphone access response: \(granted)")
            if video {
                UIApplication.wr_requestOrWarnAboutVideoAccess { _ in
                    // We still allow starting the call, even if the video permissions were not granted.
                    onGranted(granted)
                }
            } else {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                onGranted(granted)
            }
        }

    }

    func warnAboutNoInternetConnection() -> Bool {
        typealias VoiceNetworkErrorLocale = L10n.Localizable.Voice.NetworkError
        guard case .unreachable = NetworkStatus.shared.reachability else {
            return false
        }

        let alert = UIAlertController(
            title: VoiceNetworkErrorLocale.title,
            message: VoiceNetworkErrorLocale.body,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let rootViewController = appDelegate.mainWindow?.rootViewController {
            rootViewController.present(alert, animated: true)
        }

        return true
    }

    func confirmJoiningCallIfNeeded(
        alertPresenter: UIViewController,
        forceAlertModal: Bool = false,
        completion: @escaping () -> Void
    ) {
        print("🔵 [CONFIRM] confirmJoiningCallIfNeeded called")
        print("🔵 [CONFIRM] isCallOngoing: \(ZMUserSession.shared()?.isCallOngoing ?? false)")

        guard ZMUserSession.shared()?.isCallOngoing == true else {
            print("🔵 [CONFIRM] No ongoing call, calling completion immediately")
            return completion()
        }

        print("🔵 [CONFIRM] Ongoing call detected, showing alert")
        let controller = UIAlertController
            .ongoingCallJoinCallConfirmation(forceAlertModal: forceAlertModal) { confirmed in
                print("🔵 [CONFIRM] Alert response received - confirmed: \(confirmed)")
                guard confirmed else { return }
               // self.endAllCallsExceptIncoming(completion: completion)
                self.endAllCallsExceptIncoming {
                    completion()  // Explicitly call the completion after ending calls
                    print("🔵 [CONFIRM] completion() called")
                }
            }

        alertPresenter.present(controller, animated: true)
    }

    /// Ends all the active calls, except the conversation's incoming call, if any.
//    func endAllCallsExceptIncoming(completion: @escaping () -> Void) {
//        guard let sharedSession = ZMUserSession.shared() else { return }
//        sharedSession.callCenter?.activeCallConversations(in: sharedSession)
//            .filter { $0.remoteIdentifier != self.remoteIdentifier }
//            // The completion handler could potentially be called multiple times
//            // This however should not happen because there can only be one active call at a time
//            .forEach { $0.voiceChannel?.leave(userSession: sharedSession, completion: completion) }
//    }

    func endAllCallsExceptIncoming(completion: @escaping () -> Void) {
        print("🔵 [END] endAllCallsExceptIncoming called for conversation: \(self.remoteIdentifier?.uuidString ?? "unknown")")

        guard let sharedSession = ZMUserSession.shared() else {
            print("🔵 [END] No shared session - returning without calling completion")
            return
        }

        let activeConversations = sharedSession.callCenter?
            .activeCallConversations(in: sharedSession)
            .filter { $0.remoteIdentifier != self.remoteIdentifier } ?? []

        print("🔵 [END] Found \(activeConversations.count) active conversations to end")
        activeConversations.forEach { conv in
            print("🔵 [END] - Conversation ID: \(conv.remoteIdentifier?.uuidString ?? "unknown")")
        }

        if activeConversations.isEmpty {
            print("🔵 [END] No active calls to end - but completion is NOT called in current implementation!")
        }

        activeConversations.forEach { conv in
            print("🔵 [END] Calling leave() on conversation: \(conv.remoteIdentifier?.uuidString ?? "unknown")")
            conv.voiceChannel?.leave(userSession: sharedSession, completion: {
                print("🔵 [END] Leave completion called for conversation: \(conv.remoteIdentifier?.uuidString ?? "unknown")")
                completion()
                print("🔵 [END] Completion executed")
            })
        }
    }
}
