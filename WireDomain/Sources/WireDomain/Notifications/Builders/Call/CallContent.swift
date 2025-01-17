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

import WireProtos

struct CallContent: Decodable {
    let type: String
    let properties: Properties?
    let callerUserID: String?
    let callerClientID: String
    let resp: Bool
    
    enum CodingKeys: String, CodingKey {
        case type
        case properties = "props"
        case callerUserID = "src_userid"
        case callerClientID = "src_clientid"
        case resp
    }
    
    struct Properties: Decodable {
        private let videosend: String
        
        var isVideo: Bool {
            videosend == "true"
        }
    }
}

extension CallContent {
    static func decode(from calling: Calling) -> Self? {
        let decoder = JSONDecoder()
       
        guard let data = calling.content.data(using: .utf8) else {
            return nil
        }
        
        do {
            let callContent = try decoder.decode(Self.self, from: data)
            return callContent
        } catch {
            return nil
        }
    }
}
