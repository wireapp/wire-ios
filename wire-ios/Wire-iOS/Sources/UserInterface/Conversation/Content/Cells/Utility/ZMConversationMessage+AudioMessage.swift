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
import WireDataModel

extension ZMConversationMessage {
    func audioCanBeSaved() -> Bool {
        guard
            let fileMessageData,
            fileMessageData.hasLocalFileData,
            fileMessageData.isAudio
        else {
            return false
        }

        return true
    }

    var audioTrack: AudioTrack? {
        fileMessageData?.isAudio == true ? self as? AudioTrack : .none
    }
}

extension ZMAssetClientMessage: AudioTrack {
    var title: String? {
        guard let fileMessageData else { return "" }
        return fileMessageData.filename
    }

    var author: String? {
        sender?.name
    }

    var duration: TimeInterval {
        guard let fileMessageData else { return 0 }
        return TimeInterval(Float(fileMessageData.durationMilliseconds) / 1000.0)
    }

    var streamURL: URL? {
        fileMessageData?.temporaryURLToDecryptedFile()
    }

    var failedToLoad: Bool {
        get {
            false
        }
        set {
            // no-op
        }
    }
}
