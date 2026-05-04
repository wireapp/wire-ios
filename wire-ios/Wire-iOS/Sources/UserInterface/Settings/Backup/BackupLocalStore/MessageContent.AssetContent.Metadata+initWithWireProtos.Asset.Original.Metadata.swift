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

import GenericMessageProtocol
import WireBackup

extension MessageBackupModel.Content.AssetContent.Metadata {

    init(_ metadata: Asset.Original.OneOf_MetaData) {
        switch metadata {
        case let .image(imageMetadata):
            self.init(imageMetadata)
        case let .video(videoMetadata):
            self.init(videoMetadata)
        case let .audio(audioMetadata):
            self.init(audioMetadata)
        }
    }

    fileprivate init(_ imageMetaData: Asset.ImageMetaData) {
        self = .image(
            width: imageMetaData.width,
            height: imageMetaData.height,
            tag: imageMetaData.tag
        )
    }

    fileprivate init(_ videoMetaData: Asset.VideoMetaData) {
        self = .video(
            width: videoMetaData.width,
            height: videoMetaData.height,
            duration: videoMetaData.hasDurationInMillis ? videoMetaData.durationInMillis : nil
        )
    }

    fileprivate init(_ audioMetaData: Asset.AudioMetaData) {
        self = .audio(
            normalization: audioMetaData.normalizedLoudness,
            duration: audioMetaData.durationInMillis
        )
    }

}
