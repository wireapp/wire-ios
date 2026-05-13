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

final class NoConversationPlaceholderViewModel {

    struct DisplayState: Equatable {
        let kind: Kind
        let imageAsset: ImageAsset
        let imageAlpha: Double
        let imageAccessibility: ImageAccessibility
    }

    enum Kind: Equatable {
        case noConversationSelected
    }

    enum ImageAsset: Equatable {
        case shield
    }

    struct ImageAccessibility: Equatable {
        let isAccessibilityElement: Bool
        let label: String?
    }

    var displayState: DisplayState {
        DisplayState(
            kind: .noConversationSelected,
            imageAsset: .shield,
            imageAlpha: 0.24,
            imageAccessibility: ImageAccessibility(
                isAccessibilityElement: false,
                label: nil
            )
        )
    }
}
