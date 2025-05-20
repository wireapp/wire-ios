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

/*
 The synthesized implementation will create JSON like this (for text message):

 "content" : {
   "text" : {
     "_0" : {
       "text" : "Simple text message"
     }
   }
 }

This implementation will put the properties of the specific content under "content" and add a "type" attribute:

 "content" : {
   "type": "text"
   "text" : "Simple text message"
 }

 */

extension MessageBackupModel.Content {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let textContent):
            try container.encode(textContent)
        case .location(let locationContent):
            try container.encode(locationContent)
        case .asset(let assetContent):
            try container.encode(assetContent)
        }
    }

}

extension MessageBackupModel.Content.AssetContent.Metadata {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .image(let imageMetadata):
            try container.encode(imageMetadata)
        case .video(let videoMetadata):
            try container.encode(videoMetadata)
        case .audio(let audioMetadata):
            try container.encode(audioMetadata)
        case .generic(let genericMetadata):
            try container.encode(genericMetadata)
        }
    }

}
