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
import WireCoreCrypto
import WireDomain

/// **Issue:**: Use the new CC method to update the database key.
struct AppVersionMigration_4_3_0: AppVersionMigration {

    let version: SemanticVersion = "4.3.0"
    let coreCryptoProvider: CoreCryptoProviderProtocol

    func perform() async throws {
        // Skipping this migration for versions > 4.3.x because it created issues when
        // multiple accounts were logged in due to the database key not being scoped by user.
        //
        // We now use the `Journal` to verify if the migration is needed,
        // and we make sure to migrate the database key to a scoped key.
        //
        // See `CoreCryptoKeyProvider` and [WPB-20068]
    }

}
