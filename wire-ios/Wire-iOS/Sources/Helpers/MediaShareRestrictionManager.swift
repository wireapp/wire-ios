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
import WireCommonComponents
import WireSyncEngine

// MARK: - ShareableMediaSource

enum ShareableMediaSource: CaseIterable {
    case camera
    case photoLibrary
    case sketch
    case gif
    case audioRecording
    case shareExtension
    case clipboard
}

// MARK: - MediaShareRestrictionLevel

enum MediaShareRestrictionLevel {
    case none
    case securityFlag
    case APIFlag
}

// MARK: - MediaShareRestrictionManager

class MediaShareRestrictionManager {
    // MARK: - Private Properties

    private let sessionRestriction: SessionFileRestrictionsProtocol?
    private let securityFlagRestrictedTypes: [ShareableMediaSource] = [
        .photoLibrary,
        .gif,
        .shareExtension,
        .clipboard,
    ]

    // MARK: - Life cycle

    init(sessionRestriction: SessionFileRestrictionsProtocol?) {
        self.sessionRestriction = sessionRestriction
    }

    var isFileSharingFlagEnabled: Bool {
        SecurityFlags.fileSharing.isEnabled
    }

    var isPhotoLibraryEnabled: Bool {
        SecurityFlags.cameraRoll.isEnabled
    }

    // MARK: - Public Properties

    var level: MediaShareRestrictionLevel {
        if let sessionRestriction, !sessionRestriction.isFileSharingEnabled {
            return .APIFlag
        }
        return isFileSharingFlagEnabled ? .none : .securityFlag
    }

    func canUploadMedia(from source: ShareableMediaSource) -> Bool {
        switch level {
        case .none:
            true
        case .securityFlag:
            !securityFlagRestrictedTypes.contains(source)
        case .APIFlag:
            false
        }
    }

    var canDownloadMedia: Bool {
        switch level {
        case .none:
            true
        case .APIFlag, .securityFlag:
            false
        }
    }

    var canUseClipboard: Bool {
        canUploadMedia(from: .clipboard)
    }

    var canUseSpellChecking: Bool {
        canUploadMedia(from: .clipboard)
    }

    var canUseAutoCorrect: Bool {
        canUploadMedia(from: .clipboard)
    }

    var hasAccessToCameraRoll: Bool {
        switch level {
        case .none:
            true
        case .APIFlag, .securityFlag:
            false
        }
    }
}
