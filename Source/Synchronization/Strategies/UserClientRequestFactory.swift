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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import Foundation
import Cryptobox

extension NSData {
    public var base64String: String {
        return self.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
    }
}


enum UserClientRequestError: ErrorType {
    case NoPreKeys
    case NoLastPreKey
    case ClientNotRegistered
}

//TODO: when we should update last pre key or signaling keys?

public class UserClientRequestFactory {
    
    public init(keysCount: UInt = 100, missingClientsPageSize: Int = 128) {
        self.keyCount = keysCount
        self.missingClientsPageSize = missingClientsPageSize
    }
    
    public let keyCount : UInt
    public let missingClientsPageSize : Int

    public func registerClientRequest(client: UserClient, credentials: ZMEmailCredentials?, authenticationStatus: ZMAuthenticationStatus) throws -> ZMUpstreamRequest {
        
        //we don't want to generate new prekeys if we already have them
        let (preKeys, preKeysRangeMin, preKeysRangeMax) : ([CBPreKey], UInt, UInt)
        do {
            (preKeys, preKeysRangeMin, preKeysRangeMax) = try client.keysStore.generateMoreKeys(keyCount)
        }
        catch {
            throw UserClientRequestError.NoPreKeys
        }
        
        let preKeysPayloadData = preKeys.enumerate().map { (index, preKey: CBPreKey) in
            ["key": preKey.data!.base64String, "id": Int(preKeysRangeMin) + index]
        }
        
        let lastKey : CBPreKey
        do {
            lastKey = try client.keysStore.lastPreKey()
        } catch  {
            throw UserClientRequestError.NoLastPreKey
        }
        
        let lastPreKeyString = lastKey.data!.base64String
        let lastPreKeyPayloadData = ["key": lastPreKeyString, "id": CBMaxPreKeyID + 1]
        
        let apsKeyStore = APSSignalingKeysStore(fromKeychain: false)!
        apsKeyStore.saveToKeychain()
        
        let macKeyString = apsKeyStore.verificationKey.base64String
        let apnsEncriptionKeyString = apsKeyStore.decryptionKey.base64String
        
        var payload: [String: AnyObject] = [
            "type": client.type,
            "label": (client.label ?? ""),
            "model": (client.model ?? ""),
            "class": (client.deviceClass ?? ""),
            "lastkey": lastPreKeyPayloadData,
            "prekeys": preKeysPayloadData,
            "sigkeys": ["enckey": apnsEncriptionKeyString, "mackey": macKeyString],
            "cookie" : ((authenticationStatus.cookieLabel.characters.count != 0) ? authenticationStatus.cookieLabel : "")
        ]
        
        if let password = credentials?.password {
            payload["password"] = password
        }
        
        let request = ZMTransportRequest(path: "/clients", method: ZMTransportRequestMethod.MethodPOST, payload: payload)
        request.addCompletionHandler(completionHandlerForMaxRangeID(client, maxRangeID: preKeysRangeMax))
        
        let upstreamRequest = ZMUpstreamRequest(transportRequest: request)
        return upstreamRequest
    }
    
    
    func completionHandlerForMaxRangeID(client: UserClient, maxRangeID: UInt) -> ZMCompletionHandler {
        let completionHandler = ZMCompletionHandler(onGroupQueue: client.managedObjectContext!, block: { response in
            if response.result == .Success {
                client.preKeysRangeMax = Int64(maxRangeID)
            }
        })
        return completionHandler
    }
    
    public func updateClientPreKeysRequest(client: UserClient) throws -> ZMUpstreamRequest {
        if let remoteIdentifier = client.remoteIdentifier {
            let (preKeys, preKeysRangeMin, preKeysRangeMax) : ([CBPreKey], UInt, UInt)
            let startIndex = client.preKeysRangeMax
            do {
                (preKeys, preKeysRangeMin, preKeysRangeMax) = try client.keysStore.generateMoreKeys(keyCount, start: UInt(startIndex))
            }
            catch {
                throw UserClientRequestError.NoPreKeys
            }
            
            let preKeysPayloadData = preKeys.enumerate().map { (index, preKey: CBPreKey) in
                ["key": preKey.data!.base64String, "id": Int(preKeysRangeMin) + index]
            }
            
            let paylod: [String: AnyObject] = [
                "prekeys": preKeysPayloadData
            ]
            
            let request = ZMTransportRequest(path: "/clients/\(remoteIdentifier)", method: ZMTransportRequestMethod.MethodPUT, payload: paylod)
            request.addCompletionHandler(completionHandlerForMaxRangeID(client, maxRangeID: preKeysRangeMax))

            return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMUserClientNumberOfKeysRemainingKey), transportRequest: request, userInfo: nil)
        }
        throw UserClientRequestError.ClientNotRegistered
    }
    
    
    /// Password needs to be set
    public func deleteClientRequest(client: UserClient, credentials: ZMEmailCredentials) -> ZMUpstreamRequest! {
        let payload = [
                "email" : credentials.email!,
                "password" : credentials.password!
        ]
        let request =  ZMTransportRequest(path: "/clients/\(client.remoteIdentifier)", method: ZMTransportRequestMethod.MethodDELETE, payload: payload)
        return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMUserClientMarkedToDeleteKey), transportRequest: request)
    }
    
    public func fetchMissingClientKeysRequest(missingClientsMap: MissingClientsMap) -> ZMUpstreamRequest! {
        let request = ZMTransportRequest(path: "/users/prekeys", method: ZMTransportRequestMethod.MethodPOST, payload: missingClientsMap.payload)
        return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMUserClientMissingKey), transportRequest: request, userInfo: missingClientsMap.userInfo)
    }
    
    public func fetchClientsRequest() -> ZMTransportRequest! {
        return ZMTransportRequest(getFromPath: "/clients")
    }
    
}
