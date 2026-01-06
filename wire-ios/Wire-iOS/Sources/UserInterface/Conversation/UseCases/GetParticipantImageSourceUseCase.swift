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

import WireAccountImageUI
import WireDataModel
import WireSyncEngine

class GetParticipantImageSourceUseCase: GetParticipantImageSourceUseCaseProtocol {

    private let repository: GetParticipantImageSourceRepositoryProtocol

    init(repository: GetParticipantImageSourceRepositoryProtocol) {
        self.repository = repository
    }

    @MainActor
    func invoke(user: UserType) async -> WireAccountImageUI.AccountImageSource? {
        let image = await repository.invoke(user: user)
        if let image {
            return WireAccountImageUI.AccountImageSource.image(image)
        } else {
            return WireAccountImageUI.AccountImageSource.text(user.initials ?? "")
        }
    }
}
