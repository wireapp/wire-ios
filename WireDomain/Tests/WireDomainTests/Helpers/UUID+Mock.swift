//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireAPI

extension UUID {

    static let mockID1 = UUID(uuidString: "213248a1-5499-418f-8173-5010d1c1e506")!
    static let mockID2 = UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")!
    static let mockID3 = UUID(uuidString: "7e23727b-d612-4123-88c0-57e311a7e5a3")!
    static let mockID4 = UUID(uuidString: "470f0318-b69d-4af3-8364-4019493ef271")!
    static let mockID5 = UUID(uuidString: "83366d35-89fa-4121-ac80-cfc97302a43f")!
    static let mockID6 = UUID(uuidString: "edf03863-51a8-461f-ba78-439527409097")!
    static let mockID7 = UUID(uuidString: "d7f7f946-c4da-4300-998d-5aeba8affeee")!
    static let mockID8 = UUID(uuidString: "d902ed60-b2bf-44e9-b6f3-7281f0aaed36")!
    static let mockID9 = UUID(uuidString: "2fa94c25-2725-4bcb-bcda-ad5a89e62d96")!
    static let mockID10 = UUID(uuidString: "0f970654-995c-4ac6-ae67-a6aafd420b9f")!

}

extension WireAPI.QualifiedID {

    static let mockID1 = QualifiedID(uuid: .mockID1, domain: "example.com")
    static let mockID2 = QualifiedID(uuid: .mockID2, domain: "example.com")
    static let mockID3 = QualifiedID(uuid: .mockID3, domain: "example.com")
}
