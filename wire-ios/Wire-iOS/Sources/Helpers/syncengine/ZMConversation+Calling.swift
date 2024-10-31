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

import UIKit
import WireDataModel
import WireSyncEngine
import class WireCommonComponents.NetworkStatus

// TODO [WPB-9864]: Most of this code shouldn't be nested within `ZMConversation`.
extension ZMConversation {

    var isCallingSupported: Bool {
        return localParticipants.count > 1
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

    func startVideoCall() {
        if warnAboutNoInternetConnection() {
            return
        }

        warnAboutSlowConnection { abortCall in
            guard !abortCall else { return }
            self.joinVoiceChannel(video: true)
        }
    }

    func joinCall() {
        if conversationType == .group {
            voiceChannel?.muted = true
        }
        joinVoiceChannel(video: false)
    }

    func joinVoiceChannel(video: Bool) {
        guard let userSession = ZMUserSession.shared() else { return }

        let onGranted: (_ granted: Bool) -> Void = { granted in
            if granted {
                _ = self.voiceChannel?.join(video: video, userSession: userSession)
            } else {
                self.voiceChannel?.leave(userSession: userSession, completion: nil)
            }
        }

        UIApplication.wr_requestOrWarnAboutMicrophoneAccess { granted in
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

    func warnAboutSlowConnection(handler: @escaping (_ abortCall: Bool) -> Void) {

        typealias ErrorCallSlowCallLocale = L10n.Localizable.Error.Call

        guard let sessionManager = SessionManager.shared else {
            assertionFailure("requires session manager to init NetworkConditionHelper!")
            handler(false)
            return
        }

        let reachability = sessionManager.environment.reachability
        let networkInfo = NetworkInfo(serverConnection: reachability)
        if networkInfo.qualityType() == .type2G {

            let badConnectionController = UIAlertController(
                title: ErrorCallSlowCallLocale.SlowConnection.title,
                message: ErrorCallSlowCallLocale.slowConnection,
                preferredStyle: .alert
            )
            badConnectionController.addAction(UIAlertAction(title: ErrorCallSlowCallLocale.SlowConnection.callAnyway, style: .default) { _ in
                handler(false)
            })
            badConnectionController.addAction(UIAlertAction(title: L10n.Localizable.General.ok, style: .cancel) { _ in
                handler(true)
            })
            ZClientViewController.shared?.present(badConnectionController, animated: true)
        } else {
            handler(false)
        }

        reachability.tearDown()
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

    func confirmJoiningCallIfNeeded(alertPresenter: UIViewController, forceAlertModal: Bool = false, completion: @escaping () -> Void) {
        guard ZMUserSession.shared()?.isCallOngoing == true else {
            return completion()
        }

        let controller = UIAlertController.ongoingCallJoinCallConfirmation(forceAlertModal: forceAlertModal) { confirmed in
            guard confirmed else { return }
            self.endAllCallsExceptIncoming(completion: completion)
        }

        alertPresenter.present(controller, animated: true)
    }

    /// Ends all the active calls, except the conversation's incoming call, if any.
    func endAllCallsExceptIncoming(completion: @escaping () -> Void) {
        guard let sharedSession = ZMUserSession.shared() else { return }
        sharedSession.callCenter?.activeCallConversations(in: sharedSession)
            .filter { $0.remoteIdentifier != self.remoteIdentifier }
            // The completion handler could potentially be called multiple times
            // This however should not happen because there can only be one active call at a time
            .forEach { $0.voiceChannel?.leave(userSession: sharedSession, completion: completion) }
    }
}
