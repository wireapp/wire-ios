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

package import UniformTypeIdentifiers

package enum WireCellsFileCategory {

    case image
    case video
    case audio
    case document

    package init(_ fileType: UTType?) {
        guard let fileType else {
            self = .document
            return
        }

        if fileType.conforms(to: .image) {
            self = .image
        } else if fileType.conforms(to: .audio) { // `audio` must come before `.audiovisualContent`
            self = .audio
        } else if fileType.conforms(to: .audiovisualContent) {
            self = .video
        } else {
            self = .document
        }
    }

}
