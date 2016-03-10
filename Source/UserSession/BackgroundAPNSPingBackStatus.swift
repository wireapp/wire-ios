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

private let zmLog = ZMSLog(tag: "Pingback")

// MARK: - AuthenticationStatusProvider

@objc public protocol AuthenticationStatusProvider {
    var currentPhase: ZMAuthenticationPhase { get }
}

extension ZMAuthenticationStatus: AuthenticationStatusProvider {}


// MARK: - LocalNotificationDispatchType

@objc public protocol LocalNotificationDispatchType {
    func didReceiveUpdateEvents(events: [ZMUpdateEvent]?)
}

extension ZMLocalNotificationDispatcher: LocalNotificationDispatchType {}


// MARK: - EventsWithIdentifier

@objc public class EventsWithIdentifier: NSObject  {
    public let events: [ZMUpdateEvent]?
    public let identifier: NSUUID
    
    public init(events: [ZMUpdateEvent]?, identifier: NSUUID) {
        self.events = events
        self.identifier = identifier
    }
}


// MARK: - BackgroundAPNSPingBackStatus

@objc public enum PingBackStatus: Int  {
    case Pinging, Done
}

@objc public class BackgroundAPNSPingBackStatus: NSObject {

    public typealias EventsWithHandler = (events: [ZMUpdateEvent]?, handler: ZMPushResultHandler)
    
    public private(set) var eventsWithHandlerByNotificationID: [NSUUID: EventsWithHandler]
    public private(set) var backgroundActivity: ZMBackgroundActivity?
    public var status: PingBackStatus = .Done

    public var hasNotificationIDs: Bool {
        return !notificationIDs.isEmpty
    }
    
    private var notificationIDs: [NSUUID]
    private var syncManagedObjectContext: NSManagedObjectContext
    private weak var authenticationStatusProvider: AuthenticationStatusProvider?
    private weak var notificationDispatcher: LocalNotificationDispatchType?
    
    public init(
        syncManagedObjectContext moc: NSManagedObjectContext,
        authenticationProvider: AuthenticationStatusProvider,
        localNotificationDispatcher: LocalNotificationDispatchType
        ) {
        syncManagedObjectContext = moc
        notificationIDs = []
        eventsWithHandlerByNotificationID = [:]
        authenticationStatusProvider = authenticationProvider
        notificationDispatcher = localNotificationDispatcher
        super.init()
    }
    
    deinit {
        backgroundActivity?.endActivity()
    }
    
    public func nextNotificationID() -> NSUUID? {
        return notificationIDs.isEmpty ? .None : notificationIDs.removeFirst()
    }
    
    public func didReceiveVoIPNotification(eventsWithID: EventsWithIdentifier, handler: ZMPushResultHandler) {
        status = .Pinging
        let identifier = eventsWithID.identifier
        notificationIDs.append(identifier)
        eventsWithHandlerByNotificationID[identifier] = (eventsWithID.events, handler)
        
        if authenticationStatusProvider?.currentPhase == .Authenticated {
            backgroundActivity = ZMBackgroundActivity.beginBackgroundActivityWithName("Ping back to BE")
        }
        
        ZMOperationLoop.notifyNewRequestsAvailable(self)
    }
    
    public func didPerfomPingBackRequest(notificationID: NSUUID, success: Bool) {
        let eventsWithHandler = eventsWithHandlerByNotificationID.removeValueForKey(notificationID)
        defer { eventsWithHandler?.handler(.Success) }
        
        backgroundActivity?.endActivity()

        if !hasNotificationIDs {
            status = .Done
        }
    
        zmLog.debug("Pingback \(success ? "succeeded" : "failed") for notification ID: \(notificationID)")
        guard let unwrappedEvents = eventsWithHandler?.events where success else { return }
        notificationDispatcher?.didReceiveUpdateEvents(unwrappedEvents)
    }
}
