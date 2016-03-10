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
import ZMUtilities
import ZMTransport


@objc
public class PingBackRequestStrategy: ZMObjectSyncStrategy, ZMObjectStrategy {
    
    weak private(set) var authenticationStatus: ZMAuthenticationStatus?
    weak private(set) var pingBackStatus: BackgroundAPNSPingBackStatus?
    
    private(set) var pingBackSync: ZMSingleRequestSync!
    
    public init(managedObjectContext moc: NSManagedObjectContext, backgroundAPNSPingBackStatus: BackgroundAPNSPingBackStatus,
        authenticationStatus: ZMAuthenticationStatus) {
        self.authenticationStatus = authenticationStatus
        pingBackStatus = backgroundAPNSPingBackStatus
        super.init(managedObjectContext: moc)
        pingBackSync = ZMSingleRequestSync(singleRequestTranscoder: self, managedObjectContext: moc)
    }
    
    public var isSlowSyncDone: Bool {
        return true
    }
    
    public var requestGenerators: [ZMRequestGenerator] {
        return []
    }
    
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return []
    }
    
    public func nextRequest() -> ZMTransportRequest? {
        guard authenticationStatus?.currentPhase == .Authenticated else { return nil }
        guard let hasNotification = pingBackStatus?.hasNotificationIDs where hasNotification else { return nil }
        pingBackSync.readyForNextRequest()
        return pingBackSync.nextRequest()
    }
    
    public func setNeedsSlowSync() {
        // no op
    }
    
    public func processEvents(events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        // no op
    }
    
}

// MARK: - ZMSingleRequestTranscoder

extension PingBackRequestStrategy: ZMSingleRequestTranscoder {
    
    public func requestForSingleRequestSync(sync: ZMSingleRequestSync!) -> ZMTransportRequest! {
        guard sync == pingBackSync else { return nil }
        guard let nextNotificationID = pingBackStatus?.nextNotificationID() else { return nil }
        let path = "/push/fallback/\(nextNotificationID.transportString())/cancel"
        let request = ZMTransportRequest(path: path, method: .MethodPOST, payload: nil)
        request.forceToForegroundSession()
        let completion = ZMCompletionHandler(onGroupQueue: managedObjectContext)  { [weak self] response in
            self?.pingBackStatus?.didPerfomPingBackRequest(nextNotificationID, success: response.result == .Success)
        }
        
        request.addCompletionHandler(completion)
        return request
    }
    
    public func didReceiveResponse(response: ZMTransportResponse!, forSingleRequest sync: ZMSingleRequestSync!) {
        // no op
    }
    
}
