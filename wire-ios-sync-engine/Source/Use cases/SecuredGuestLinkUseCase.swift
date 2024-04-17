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

    func invoke(password: String?, completion: @escaping (Result<String, Error>) -> Void)

}

public struct SecuredGuestLinkUseCase: SecuredGuestLinkUseCaseProtocol {

    private let conversation: ZMConversation

    public init(
        conversation: ZMConversation
    ) {
        self.conversation = conversation
    }

    public func invoke(password: String?, completion: @escaping (Result<String, Error>) -> Void) {

        if conversation.isLegacyAccessMode {
            conversation.setAllowGuests(true) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    conversation.createWirelessLink(password: password, completion)
                }
            }
        } else {
            conversation.createWirelessLink(password: password, completion)
        }
    }

}
