//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public struct AcmeDirectoriesResponse: Codable {

    var newNonce: String
    var newAccount: String
    var newOrder: String
    var revokeCert: String
    var keyChange: String

}

public struct ACMEResponse: Decodable {

    var nonce: String
    var location: String
    var response: Data

}

public struct ChallengeResponse {

    var type: String
    var url: String
    var status: String
    var token: String
    var nonce: String

}
