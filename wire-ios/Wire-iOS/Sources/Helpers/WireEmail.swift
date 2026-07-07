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

import Foundation
import WireTransport

struct WireEmail: Codable {
    let supportEmail: String
    let callingSupportEmail: String

    static func shared() -> WireEmail? {
        guard Bundle.backendBundle != nil else {
            if let supportEmail = BackendEnvironment.shared.supportEmail {
                return WireEmail(email: supportEmail)
            }
            return nil
        }
        
        return .init(forResource: "email", withExtension: "json")!
    }

    private init?(forResource resource: String, withExtension fileExtension: String) {
        do {
            let fileURL = Bundle.fileURL(for: resource, with: fileExtension)!
            self = try fileURL.decode(WireEmail.self)
        } catch {
            return nil
        }
    }

    private init(email: String) {
        self.supportEmail = email
        self.callingSupportEmail = email
    }
}
