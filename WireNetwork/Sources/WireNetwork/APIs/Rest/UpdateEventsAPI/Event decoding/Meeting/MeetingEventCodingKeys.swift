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

enum MeetingEventCodingKeys: String, CodingKey {

    case qualifiedID = "qualified_id"
    case time

    // TODO: [WPB-26733] remove once the backend no longer sends the qualified ID under "data"
    // revert commit c76b59db669eec08127f83bb2005a1f176bcb62a
    case legacyQualifiedID = "data"

}

// TODO: [WPB-26733] remove once the backend no longer sends the qualified ID under "data"
extension KeyedDecodingContainer<MeetingEventCodingKeys> {

    /// Decodes the meeting's qualified ID, falling back to the incorrect `data` key
    /// which the backend currently sends instead of `qualified_id`.
    func decodeQualifiedID() throws -> QualifiedIDV0 {
        try decodeIfPresent(QualifiedIDV0.self, forKey: .qualifiedID)
            ?? decode(QualifiedIDV0.self, forKey: .legacyQualifiedID)
    }

}
