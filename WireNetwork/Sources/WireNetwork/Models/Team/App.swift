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

public struct App: Equatable, Sendable {

    /// The app name.

    public let name: String

    public let category: String

    public let description: String

    /// Accent color of the app

    public let accentID: Int

    /// The app's profile image assets

    public let assets: [UserAsset]

    /// Creates a new `App` instance.
    ///
    /// - Parameters:
    ///   - name: The team name.
    ///   - category: The category of the app.
    ///   - description: A description of the app.
    ///   - accentID: The color accent identifier of the user.
    ///   - assets: The user's profile image assets.
    public init(
        name: String,
        category: String,
        description: String,
        accentID: Int,
        assets: [UserAsset]
    ) {
        self.name = name
        self.category = category
        self.description = description
        self.accentID = accentID
        self.assets = assets
    }

}
