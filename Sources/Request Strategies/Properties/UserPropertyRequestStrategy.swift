//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

fileprivate enum UserProperty: CaseIterable {
    case readReceiptsEnabled
}

extension UserProperty {
    static let propertiesPath = "properties"
    
    var propertyName: String {
        switch self {
        case .readReceiptsEnabled:
            return "readReceiptsEnabled"
        }
    }
    
    var serverName: String {
        switch self {
        case .readReceiptsEnabled:
            return "WIRE_ENABLE_READ_RECEIPTS"
        }
    }
    
    init?(serverName: String) {
        let matchingProperty = UserProperty.allCases.first { return $0.serverName == serverName }
        guard let property = matchingProperty else {
            return nil
        }
        self = property
    }

    init?(propertyName: String) {
        let matchingProperty = UserProperty.allCases.first { return $0.propertyName == propertyName }
        guard let property = matchingProperty else {
            return nil
        }
        self = property
    }
    
    static func upstreamRequest(newValue: ZMTransportData, property: UserProperty) -> ZMTransportRequest {
        let path = [UserProperty.propertiesPath, property.serverName].joined(separator: "/")
        return ZMTransportRequest(path: path, method: .methodPUT, payload: newValue)
    }
    
    static func downstreamRequest(for property: UserProperty) -> ZMTransportRequest {
        let path = [UserProperty.propertiesPath, property.serverName].joined(separator: "/")
        return ZMTransportRequest(getFromPath: path)
    }
}

public class UserPropertyRequestStrategy : AbstractRequestStrategy {
    
    var modifiedSync : ZMUpstreamModifiedObjectSync!

    override public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        let allProperties = UserProperty.allCases.map(\.propertyName)
        self.modifiedSync = ZMUpstreamModifiedObjectSync(transcoder: self,
                                                         entityName: ZMUser.entityName(),
                                                         update: nil,
                                                         filter: ZMUser.predicateForSelfUser(),
                                                         keysToSync: allProperties,
                                                         managedObjectContext: managedObjectContext)
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return modifiedSync.nextRequest()
    }
}


extension UserPropertyRequestStrategy : ZMUpstreamTranscoder {
    
    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let selfUser = managedObject as? ZMUser else { return nil }
        
        let allProperties = Set(UserProperty.allCases.map(\.propertyName))
        
        let intersect = allProperties.intersection(keys)
        
        guard let first = intersect.first,
              let property = UserProperty(propertyName: first) else {
            return nil
        }
        
        let request: ZMTransportRequest
        
        switch property {
        case .readReceiptsEnabled:
            let stringValue = selfUser.readReceiptsEnabled ? "true" : "false"
            request = UserProperty.upstreamRequest(newValue: stringValue as ZMTransportData,
                                                   property: property)
        }
        
        return ZMUpstreamRequest(keys: keys, transportRequest: request)
    }
    
    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        return nil
    }
    
    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        return false
    }
    
    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        return false
    }
    
    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }
    
    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        return nil // we will never insert objects
    }
    
    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // we will never insert objects
    }
    
    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }
    
}

extension UserPropertyRequestStrategy : ZMContextChangeTrackerSource {
    
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [modifiedSync]
    }
}

extension UserPropertyRequestStrategy : ZMEventConsumer {
    static let UpdateEventKey = "key"
    static let UpdateEventValue = "value"
    
    
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard event.type.isOne(of: [ZMUpdateEventType.userPropertiesSet, ZMUpdateEventType.userPropertiesDelete]),
                  let keyChanged = event.payload[UserPropertyRequestStrategy.UpdateEventKey] as? String,
                  let property = UserProperty(serverName: keyChanged) else {
                continue
            }
            
            let value = event.payload[UserPropertyRequestStrategy.UpdateEventValue]
            switch (property, event.type) {
            case (.readReceiptsEnabled, .userPropertiesSet):
                guard let boolValue = value as? Bool else {
                    return
                }
                    
                let user = ZMUser.selfUser(in: managedObjectContext)
                user.setReadReceiptsEnabled(boolValue, synchronize: false)
                
            case (.readReceiptsEnabled, .userPropertiesDelete):
                let user = ZMUser.selfUser(in: managedObjectContext)
                user.setReadReceiptsEnabled(false, synchronize: false)
                
            default:
                break
            }
        }
    }
    
}
