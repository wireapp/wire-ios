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


@preconcurrency import Foundation

public enum DarwinNotification {
    public static let requestingPushChannelAccess = "com.wire.RequestingPushChannelAccess"
    public static let releasingPushChannelAccess  = "com.wire.ReleasingPushChannelAccess"
}

public class DarwinNotificationManager {

    public static let shared = DarwinNotificationManager()

    private init() {}


    private var callbacks: [String: () -> Void] = [:]

    // Method to post a Darwin notification
    public func postNotification(name: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(notificationCenter, CFNotificationName(name as CFString), nil, nil, true)
    }


    public func startObserving(name: String, callback: @escaping () -> Void) {
        callbacks[name] = callback

        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()

        CFNotificationCenterAddObserver(notificationCenter,
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        DarwinNotificationManager.notificationCallback,
                                        name as CFString,
                                        nil,
                                        .deliverImmediately)
    }


    public func stopObserving(name: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveObserver(notificationCenter, Unmanaged.passUnretained(self).toOpaque(), CFNotificationName(name as CFString), nil)
        callbacks.removeValue(forKey: name)
    }


    private static let notificationCallback: CFNotificationCallback = { center, observer, name, _, _ in
        guard let observer = observer else { return }
        let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()

        if let name = name?.rawValue as String?, let callback = manager.callbacks[name] {
            callback()
        }
    }
 }
//public enum DarwinNotify {
//    private static var center: CFNotificationCenter {
//        CFNotificationCenterGetDarwinNotifyCenter()
//    }
//
//    // Trampoline: top-level C function pointer
//    private static let notificationCallback: CFNotificationCallback = { _, observer, _, _, _ in
//        if let observer = observer {
//            let handler = Unmanaged<AnyObject>.fromOpaque(observer).takeUnretainedValue()
//            (handler as? () -> Void)?()
//        }
//    }
//
//    @discardableResult
//    static func observe(_ name: CFString, _ handler: @escaping () -> Void) -> NSObject {
//        // Store handler in an object to keep it alive
//        let box = HandlerBox(handler)
//        let pointer = Unmanaged.passRetained(box).toOpaque()
//
//        CFNotificationCenterAddObserver(
//            center,
//            pointer,
//            notificationCallback,
//            name,
//            nil,
//            .deliverImmediately
//        )
//
//        return box
//    }
//
//    public static func post(_ name: CFString) {
//        CFNotificationCenterPostNotification(center, CFNotificationName(name), nil, nil, true)
//    }
//
//    static func removeObserver(_ token: NSObject) {
//        let pointer = Unmanaged.passUnretained(token).toOpaque()
//        CFNotificationCenterRemoveEveryObserver(center, pointer)
//        Unmanaged.passUnretained(token).release()
//    }
//
//    // Box object to hold the closure
//    private final class HandlerBox: NSObject {
//        let handler: () -> Void
//        init(_ handler: @escaping () -> Void) {
//            self.handler = handler
//        }
//        override func responds(to aSelector: Selector!) -> Bool { true }
//        override func forwardingTarget(for aSelector: Selector!) -> Any? { handler }
//        func callAsFunction() { handler() }
//    }
//}
