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

import Foundation

public struct WireDriveFileTemplate: Equatable, Hashable, Sendable {

    // TODO: [WPB-22926] Reflect all template kind from the server when endpoint ready
    public enum Kind: Equatable, Hashable, Sendable {
        case document
        case spreadsheet
        case presentation
    }

    public let kind: Kind
    public let editable: Bool?
    public let label: String
    public let id: String

    package init(
        kind: Kind,
        editable: Bool?,
        label: String,
        UUID: String
    ) {
        self.kind = kind
        self.editable = editable
        self.label = label
        self.id = UUID
    }
}

public extension WireDriveFileTemplate {
    var fileExtension: String {
        URL(fileURLWithPath: id).pathExtension
    }
}
