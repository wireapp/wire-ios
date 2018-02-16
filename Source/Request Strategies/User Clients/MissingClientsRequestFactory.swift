//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel
import WireRequestStrategy


public final class MissingClientsRequestFactory {
    
    let pageSize : Int
    public init(pageSize: Int = 128) {
        self.pageSize = pageSize
    }
    
    public func fetchMissingClientKeysRequest(_ missingClients: Set<UserClient>) -> ZMUpstreamRequest! {
        let map = MissingClientsMap(Array(missingClients), pageSize: pageSize)
        let request = ZMTransportRequest(path: "/users/prekeys", method: ZMTransportRequestMethod.methodPOST, payload: map.payload as ZMTransportData?)
        return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMUserClientMissingKey), transportRequest: request, userInfo: map.userInfo)
    }
    
}

public func identity<T>(value: T) -> T {
    return value
}

public struct MissingClientsMap {
    
    /// The mapping from user-id's to an array of missing clients for that user `{ <user-id>: [<client-id>] }`
    let payload: [String: [String]]
    /// The `MissingClientsRequestUserInfoKeys.clients` key holds all missing clients
    let userInfo: [String: [String]]
    
    public init(_ missingClients: [UserClient], pageSize: Int) {
        
        let addClientIdToMap = { (clientsMap: [String : Set<String>], missingClient: UserClient) -> [String: Set<String>] in
            var clientsMap = clientsMap
            let missingUserId = missingClient.user!.remoteIdentifier!.transportString()
            var clientSet = clientsMap[missingUserId] ?? Set<String>()
            clientSet.insert(missingClient.remoteIdentifier!)
            clientsMap[missingUserId] = clientSet
            return clientsMap
        }
        
        var users = Set<ZMUser>()
        let missing = missingClients.filter {
            guard let user = $0.user,
                let _ = user.remoteIdentifier else { return false }
            users.insert(user)
            return users.count <= pageSize
        }
        
        let setPayload = missing.reduce([String: Set<String>](), addClientIdToMap)
        
        payload = setPayload.mapKeysAndValues(keysMapping: identity, valueMapping: { return Array($1) })
        userInfo = [MissingClientsRequestUserInfoKeys.clients: missing.map { $0.remoteIdentifier! }]
    }
}
