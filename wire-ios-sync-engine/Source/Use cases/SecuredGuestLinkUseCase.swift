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

import Foundation

// sourcery: AutoMockable
public protocol SecuredGuestLinkUseCaseProtocol {

    func invoke(password: String, completion: @escaping (Result<String, Error>) -> Void)

}

struct SecuredGuestLinkUseCase: SecuredGuestLinkUseCaseProtocol {

    private let conversation: ZMConversation
    private let userSession: ZMUserSession

    init(
        conversation: ZMConversation,
        userSession: ZMUserSession
    ) {
        self.conversation = conversation
        self.userSession = userSession
    }

    func invoke(password: String, completion: @escaping (Result<String, Error>) -> Void) {
        conversation.updateAccessAndCreateWirelessLink(password: password, in: userSession, completion)
    }
}
