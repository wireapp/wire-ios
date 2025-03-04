//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAccountImageUI
import WireDataModel
import WireSyncEngine

protocol GetParticipantImageSourceUseCaseProtocol {
    func invoke(user: UserType?) async -> WireAccountImageUI.AccountImageSource
}

class GetParticipantImageSourceUseCase: GetParticipantImageSourceUseCaseProtocol {

    private let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    @MainActor
    func invoke(user: UserType?) async -> WireAccountImageUI.AccountImageSource {
        guard let user else {
            return WireAccountImageUI.AccountImageSource.text("")
        }

        return await withCheckedContinuation { continuation in
            user.fetchProfileImage(
                session: userSession,
                imageCache: UIImage.defaultUserImageCache,
                sizeLimit: 32,
                isDesaturated: false
            ) { image, _ in
                if let image {
                    continuation.resume(returning: WireAccountImageUI.AccountImageSource.image(image))
                }
            }
        }
    }
}
