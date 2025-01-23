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
import WireAPI

protocol AuthenticationDependency: Dependency {
    var userIdentifier: UUID { get }
}

class AuthenticationComponent: Component<AuthenticationDependency> {
    
    var cookieStorage: CookieStorageProtocol {
        storageComponent.cookieStorage
    }
    
    var coreData: CoreDataStack {
        storageComponent.coreData
    }
    
    var userDefaultsStorage: UserDefaults {
        storageComponent.userDefaults
    }
    
    var authenticatedComponent: AuthenticatedComponent {
        AuthenticatedComponent(parent: self)
    }
    
    // MARK: - Private
    
    private var storageComponent: StorageComponent {
        StorageComponent(parent: self)
    }
}
