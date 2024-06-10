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

/// Available cipher suites in the MLS protocol.

public enum MLSCipherSuite: Int, Codable {

    case MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519 = 1

    case MLS_128_DHKEMP256_AES128GCM_SHA256_P256 = 2

    case MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519 = 3

    case MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448 = 4

    case MLS_256_DHKEMP521_AES256GCM_SHA512_P521 = 5

    case MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448 = 6

    case MLS_256_DHKEMP384_AES256GCM_SHA384_P384 = 7

}
