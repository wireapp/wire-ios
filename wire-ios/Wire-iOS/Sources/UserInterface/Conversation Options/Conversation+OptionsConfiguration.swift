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

import WireSyncEngine

// MARK: - GuestLinkFeatureStatus

enum GuestLinkFeatureStatus {
    case enabled
    case disabled
    case unknown
}

// MARK: - ZMConversation.OptionsConfigurationContainer

extension ZMConversation {
    final class OptionsConfigurationContainer: NSObject, ConversationGuestOptionsViewModelConfiguration,
        ConversationServicesOptionsViewModelConfiguration, ZMConversationObserver {
        private var conversation: ZMConversation
        private var token: NSObjectProtocol?
        private let userSession: ZMUserSession
        var allowGuestsChangedHandler: ((Bool) -> Void)?
        var allowServicesChangedHandler: ((Bool) -> Void)?
        var guestLinkFeatureStatusChangedHandler: ((GuestLinkFeatureStatus) -> Void)?

        init(conversation: ZMConversation, userSession: ZMUserSession) {
            self.conversation = conversation
            self.userSession = userSession
            super.init()
            self.token = ConversationChangeInfo.add(observer: self, for: conversation)

            conversation.canGenerateGuestLink(in: userSession) { [weak self] result in
                switch result {
                case .success(true):
                    self?.guestLinkFeatureStatus = .enabled
                case .success(false):
                    self?.guestLinkFeatureStatus = .disabled
                case .failure:
                    self?.guestLinkFeatureStatus = .unknown
                }
            }
        }

        var isConversationFromSelfTeam: Bool {
            let selfUser = ZMUser.selfUser(inUserSession: userSession)

            return conversation.teamRemoteIdentifier == selfUser.teamIdentifier
        }

        var allowGuests: Bool {
            conversation.allowGuests
        }

        var allowServices: Bool {
            conversation.allowServices
        }

        var guestLinkFeatureStatus: GuestLinkFeatureStatus = .unknown {
            didSet {
                guestLinkFeatureStatusChangedHandler?(guestLinkFeatureStatus)
            }
        }

        var isCodeEnabled: Bool {
            conversation.accessMode?.contains(.code) ?? false
        }

        var areGuestPresent: Bool {
            conversation.areGuestsPresent
        }

        var areServicePresent: Bool {
            conversation.areServicesPresent
        }

        func setAllowGuests(_ allowGuests: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
            userSession.makeSetConversationGuestsAndServicesUseCase().invoke(
                conversation: conversation,
                allowGuests: allowGuests,
                allowServices: conversation.allowServices
            ) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }

        func setAllowServices(_ allowServices: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
            userSession.makeSetConversationGuestsAndServicesUseCase().invoke(
                conversation: conversation,
                allowGuests: conversation.allowGuests,
                allowServices: allowServices
            ) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }

        func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
            if changeInfo.allowGuestsChanged {
                allowGuestsChangedHandler?(allowGuests)
            }

            if changeInfo.allowServicesChanged {
                allowServicesChangedHandler?(allowServices)
            }
        }

        func fetchConversationLink(completion: @escaping (Result<(uri: String?, secured: Bool), Error>) -> Void) {
            conversation.fetchWirelessLink(in: userSession, completion)
        }

        func deleteLink(completion: @escaping (Result<Void, Error>) -> Void) {
            conversation.deleteWirelessLink(in: userSession, completion)
        }
    }
}
