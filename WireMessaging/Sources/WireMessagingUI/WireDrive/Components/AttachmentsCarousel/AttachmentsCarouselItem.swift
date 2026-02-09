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

public import UIKit

public struct AttachmentsCarouselItem: Identifiable, Sendable, Equatable {

    public enum State: Sendable, Equatable {
        case uploading(progress: Double)
        case uploaded
        case failed
    }

    public enum Kind: Sendable, Equatable {
        case image(thumbnail: UIImage?)
        case video(thumbnail: UIImage?)
        case audio(samples: [Double]?)
        case document
    }

    public var id: UUID
    public var state: State
    public var kind: Kind
    public var name: String
    public var fileExtension: String?
    public var size: String
    var fileIcon: FileType

}
