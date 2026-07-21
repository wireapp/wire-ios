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

struct MeetingCreateEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<MeetingEventCodingKeys>
    ) throws -> MeetingCreateEvent {
        // TODO: [WPB-26733] restore this code once the backend no longer sends the qualified ID under "data"
        // let qualifiedID = try container.decode(
        //     QualifiedIDV0.self,
        //     forKey: .qualifiedID
        // )

        // TODO: [WPB-26733] remove this code once the backend no longer sends the qualified ID under "data"
        let qualifiedID = try container.decodeQualifiedID()

        return MeetingCreateEvent(meetingID: qualifiedID.toAPIModel())
    }

}
