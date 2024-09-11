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

/*
import UIKit
import WireDataModel
import WireSyncEngine
import WireReusableUIComponents

// TODO: remove file

@MainActor
func AccountImage(
    _ userSession: UserSession,
    _ account: Account,
    _ miniatureAccountImageFactory: MiniatureAccountImageFactory
) async -> UIImage {

    // TODO: trigger fetching?

    if let team = userSession.selfUser.membership?.team, let teamImageViewContent = team.teamImageViewContent ?? account.teamImageViewContent {

        // Team image
        if case .teamImage(let data) = teamImageViewContent, let accountImage = UIImage(data: data) {
            return accountImage
        }

        // Team initials
        let teamName: String
        if case .teamName(let value) = teamImageViewContent {
            teamName = value
        } else {
            teamName = team.name ?? account.teamName ?? ""
        }
        let initials = teamName.trimmingCharacters(in: .whitespacesAndNewlines).first.map { "\($0)" } ?? ""
        let accountImage = await miniatureAccountImageFactory.createImage(initials: initials, backgroundColor: .white)
        return accountImage

    } else {

        // User image
        if let data = account.imageData, let accountImage = UIImage(data: data) {
            return accountImage
        }

        // User initials
        let personName = PersonName.person(withName: account.userName, schemeTagger: nil)
        let accountImage = await miniatureAccountImageFactory.createImage(initials: personName.initials, backgroundColor: .white)
        return accountImage
    }
}
*/
