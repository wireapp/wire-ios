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

import WireDataModel
import WireFoundation
import WireSyncEngine

enum UserStatusPreset {
    static let inMeetingEmoji = "🎧"
    static let inMeetingText = "In a meeting"
    static let inMeeting = "\(inMeetingEmoji) \(inMeetingText)"
}

protocol CallStatusTextEditable: AnyObject {
    var textStatus: String? { get set }
}

extension ZMUser: CallStatusTextEditable {}

final class CallStatusAutoUpdateController {

    private enum StorageKey: String, DefaultsKey {
        case hasStoredPreCallStatus
        case preCallAvailability
        case preCallTextStatus
    }

    private let userSession: UserSession
    private let userDefaults: PrivateUserDefaults<StorageKey>

    var callConversationProvider: CallConversationProvider?

    init(
        userSession: UserSession,
        userDefaults: any UserDefaultsProtocol = UserDefaults.standard
    ) {
        self.userSession = userSession
        self.userDefaults = PrivateUserDefaults(
            userID: userSession.selfUser.remoteIdentifier,
            storage: userDefaults
        )
    }

    func handleCallStateChange(
        callState: CallState,
        previousCallState: CallState?
    ) {
        if callState.isEstablishedCall, previousCallState?.isEstablishedCall != true {
            applyAutomaticStatusIfNeeded()
        }

        restorePreCallStatusIfNeeded()
    }

    func syncWithCurrentCallState() {
        restorePreCallStatusIfNeeded()
    }

    private func applyAutomaticStatusIfNeeded() {
        guard !hasStoredPreCallStatus else { return }

        storeCurrentStatus()
        updateSelfUserStatus(
            availability: .busy,
            textStatus: UserStatusPreset.inMeeting
        )
    }

    private func restorePreCallStatusIfNeeded() {
        guard hasStoredPreCallStatus, !hasEstablishedCalls else { return }

        let availability = Availability(
            rawValue: userDefaults.integer(forKey: .preCallAvailability)
        ) ?? .none
        let textStatus = userDefaults.object(forKey: .preCallTextStatus) as? String

        updateSelfUserStatus(
            availability: availability,
            textStatus: textStatus
        )
        clearStoredStatus()
    }

    private var hasEstablishedCalls: Bool {
        !(callConversationProvider?.establishedCallConversations.isEmpty ?? true)
    }

    private var hasStoredPreCallStatus: Bool {
        userDefaults.bool(forKey: .hasStoredPreCallStatus)
    }

    private func storeCurrentStatus() {
        let selfUser = userSession.selfUser
        userDefaults.set(true, forKey: .hasStoredPreCallStatus)
        userDefaults.set(selfUser.availability.rawValue, forKey: .preCallAvailability)

        if let textStatus = selfUser.textStatus {
            userDefaults.set(textStatus, forKey: .preCallTextStatus)
        } else {
            userDefaults.removeObject(forKey: .preCallTextStatus)
        }
    }

    private func clearStoredStatus() {
        userDefaults.removeObject(forKey: .hasStoredPreCallStatus)
        userDefaults.removeObject(forKey: .preCallAvailability)
        userDefaults.removeObject(forKey: .preCallTextStatus)
    }

    private func updateSelfUserStatus(
        availability: Availability,
        textStatus: String?
    ) {
        userSession.perform { [userSession] in
            let selfUser = userSession.editableSelfUser
            selfUser.availability = availability

            if let textStatusEditable = selfUser as? CallStatusTextEditable {
                textStatusEditable.textStatus = textStatus
            }

            if let zmUser = selfUser as? ZMUser {
                zmUser.setLocallyModifiedKeys(["textStatus"])
            }
        }
    }
}

private extension CallState {
    var isEstablishedCall: Bool {
        switch self {
        case .established, .establishedDataChannel:
            true
        default:
            false
        }
    }
}
