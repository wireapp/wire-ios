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

public import UIKit
public import UniformTypeIdentifiers

public struct AttachmentsCarouselItem: Identifiable {

    public enum State {
        case uploading(progress: Double)
        case uploaded
        case failed
    }

    public enum Kind {
        case image(thumbnail: UIImage)
        case video(thumbnail: UIImage)
        case audio(samples: [Double])
        case document(type: UTType?)
    }

    public let id: UUID
    public let state: State
    public let kind: Kind
    public let name: String
    public let size: String

    public init(id: UUID, state: State, kind: Kind, name: String, size: String) {
        self.id = id
        self.state = state
        self.kind = kind
        self.name = name
        self.size = size
    }

}
