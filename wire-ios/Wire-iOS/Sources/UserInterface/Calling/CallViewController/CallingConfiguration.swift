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

// MARK: - CallingConfiguration

struct CallingConfiguration {
    // MARK: Internal

    enum StreamLimit {
        case noLimit
        case limit(amount: Int)
    }

    static var config = Self.default

    let canSwipeToDismissCall: Bool
    let audioTilesEnabled: Bool
    let paginationEnabled: Bool
    let isAudioCallColorSchemable: Bool
    let canAudioCallHideOverlay: Bool
    let streamLimit: StreamLimit

    #if DEBUG
        static func testHelper_resetDefaultConfig() {
            config = Self.default
        }
    #endif

    // MARK: Private

    private static let `default` = Self.largeConferenceCalls
}

extension CallingConfiguration {
    static var legacy = CallingConfiguration(
        canSwipeToDismissCall: true,
        audioTilesEnabled: false,
        paginationEnabled: false,
        isAudioCallColorSchemable: true,
        canAudioCallHideOverlay: false,
        streamLimit: .limit(amount: 12)
    )

    static var largeConferenceCalls = CallingConfiguration(
        canSwipeToDismissCall: false,
        audioTilesEnabled: true,
        paginationEnabled: true,
        isAudioCallColorSchemable: false,
        canAudioCallHideOverlay: true,
        streamLimit: .noLimit
    )
}
