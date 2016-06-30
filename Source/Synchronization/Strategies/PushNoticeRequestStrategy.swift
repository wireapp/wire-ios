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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation


@objc
public class PushNoticeRequestStrategy: ZMObjectSyncStrategy, ZMObjectStrategy {
    
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
        guard authenticationStatus?.currentPhase == .Authenticated && pingBackStatus?.status == .FetchingNotice,
              let hasNotification = pingBackStatus?.hasNoticeNotificationIDs where hasNotification
        else { return nil }
        
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

extension PushNoticeRequestStrategy: ZMSingleRequestTranscoder {
    
    public func requestForSingleRequestSync(sync: ZMSingleRequestSync!) -> ZMTransportRequest! {
        guard sync == pingBackSync,
              let nextEventsWithID = pingBackStatus?.nextNoticeNotificationEventsWithID(),
              let selfClientID = ZMUser.selfUserInContext(self.managedObjectContext).selfClient()?.remoteIdentifier
        else { return nil }
        
        let nextNotificationID = nextEventsWithID.identifier
        let basePath = "/notifications/\(nextNotificationID.transportString())"
        let clientComponent = NSURLQueryItem(name: "client", value: selfClientID)
        let fallbackComponent = NSURLQueryItem(name: "cancel_fallback", value: "true")
        let path = NSURLComponents(string: basePath)
        path!.queryItems = [clientComponent, fallbackComponent]
        
        let request = ZMTransportRequest(path: path!.string, method: .MethodGET, payload: nil)
        request.forceToVoipSession()

        let completion = ZMCompletionHandler(onGroupQueue: managedObjectContext)  { [weak self] response in
            let success = response.result == .Success
            var events : [ZMUpdateEvent] = []
            if success {
                events = ZMUpdateEvent.eventsArrayFromTransportData(response.payload, source: ZMUpdateEventSource.PushNotification) ?? []
            }
            self?.pingBackStatus?.didFetchNoticeNotification(nextEventsWithID, responseStatus: response.result, events: events)
        }
        
        request.addCompletionHandler(completion)
        
        APNSPerformanceTracker.sharedTracker.trackNotification(
            nextNotificationID,
            state: .PingBackStrategy(notice: true),
            analytics: managedObjectContext.analytics
        )
        
        return request
    }
    
    public func didReceiveResponse(response: ZMTransportResponse!, forSingleRequest sync: ZMSingleRequestSync!) {
        // no op
    }
    
}


