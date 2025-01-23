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

import NeedleFoundation
import WireDataModel

final class RootComponent: BootstrapComponent {
    
    enum Failure: Error {
        case missingApplicationGroupID
    }
    
    private let userIdentifier: UUID
    private let applicationIdentifier: String
    
    init(userIdentifier: UUID) throws {
        guard let appGroupID = Bundle.main.infoDictionary?["WireGroupId"] as? String else {
            throw Failure.missingApplicationGroupID
        }
        
        self.userIdentifier = userIdentifier
        self.applicationIdentifier = "group.\(appGroupID)"
        
        super.init()
    }
    
    // MARK: - Components
    
    var authenticationComponent: AuthenticationComponent {
        AuthenticationComponent(parent: self)
    }
    
    var applicationContainer: URL {
        FileManager.sharedContainerDirectory(for: applicationIdentifier)
    }
    
    var accountManager: AccountManager {
        AccountManager(sharedDirectory: applicationContainer)
    }
    
    var selectedAccount: Account {
        accountManager.account(with: userIdentifier)!
    }
    
}


