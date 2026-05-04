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

import UniformTypeIdentifiers

public struct SendableImage {

    public let name: String
    public let utType: UTType?
    public let data: Data

    public init(
        name: String?,
        utType: UTType?,
        data: Data
    ) {
        if let utType {
            self.utType = utType
        } else {
            self.utType = Self.determineUTType(from: data)
        }

        if let name {
            self.name = name
        } else if let fileExtension = self.utType?.preferredFilenameExtension {
            self.name = "picture.\(fileExtension)"
        } else {
            self.name = "picture"
        }

        self.data = data
    }

    private static func determineUTType(from data: Data) -> UTType? {
        guard
            !data.isEmpty,
            let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
            let uti = CGImageSourceGetType(imageSource) as String?
        else {
            return nil
        }

        return UTType(uti)
    }

}
