////
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

fileprivate let zmLog = ZMSLog(tag: "rich-profile")

public class UserRichProfileRequestStrategy : AbstractRequestStrategy {
    
    var modifiedSync: ZMDownstreamObjectSync!
    
    override public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
                         applicationStatus: ApplicationStatus) {
        
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        self.modifiedSync = ZMDownstreamObjectSync(transcoder: self,
                                                         entityName: ZMUser.entityName(),
                                                         predicateForObjectsToDownload: ZMUser.predicateForUsersToUpdateRichProfile(),
                                                         managedObjectContext: managedObjectContext)
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return modifiedSync.nextRequest()
    }
}

extension UserRichProfileRequestStrategy : ZMDownstreamTranscoder {
    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest! {
        guard let user = object as? ZMUser else { fatal("Object \(object.classForCoder) is not ZMUser") }
        guard let remoteIdentifier = user.remoteIdentifier else { fatal("User does not have remote identifier") }
        let path = "/users/\(remoteIdentifier)/rich_info"
        return ZMTransportRequest(path: path, method: .methodGET, payload: nil)
    }
    
    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let user = object as? ZMUser else { fatal("Object \(object.classForCoder) is not ZMUser") }

        // TODO: Temporary code for testing end to end until backend is ready
        if response.httpStatus == 404 && (response.payload?.asDictionary()?["label"] as? String == "no-endpoint") {
            let department = ["Hardware Development and Administration", "Department of Extranet Programming Development", "Hardware Maintenance Division", "Internet Security Team", "PC Backup Team"]
            let name = ["Lolicia", "Riina", "Hemingr", "Jožica", "Ilmari"]
            
            let fakeData = [
                "fields" : [
                    [
                        "type" : "Department",
                        "value" : department[Int(arc4random_uniform(UInt32(department.count)))]
                    ],
                    [
                        "type" : "Name",
                        "value" : name[Int(arc4random_uniform(UInt32(name.count)))]
                    ]
                ]
            ]
            let fakeResponse = ZMTransportResponse(payload: fakeData as NSDictionary, httpStatus: 200, transportSessionError: nil)
            update(object, with: fakeResponse, downstreamSync: downstreamSync)
        }
        user.needsRichProfileUpdate = false
    }
    
    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        struct Response: Decodable {
            struct Field: Decodable {
                var type: String
                var value: String
            }
            var fields: [Field]
        }
        
        guard let user = object as? ZMUser else { fatal("Object \(object.classForCoder) is not ZMUser") }
        guard let data = response.rawData else { zmLog.error("Response has no rawData"); return }
        do {
            let values = try JSONDecoder().decode(Response.self, from: data)
            user.richProfile = values.fields.map { UserRichProfileField(type: $0.type, value: $0.value) }
        } catch {
            zmLog.error("Failed to decode response: \(error)"); return
        }
        user.needsRichProfileUpdate = false
    }
}

extension UserRichProfileRequestStrategy : ZMContextChangeTrackerSource {
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [modifiedSync]
    }
}
