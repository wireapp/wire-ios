//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import UserNotifications
import WireTransport
import WireCommonComponents
import OSLog

extension Logger {

    private static var subsystem = Bundle.main.bundleIdentifier!

    static let simpleNSE = Logger(subsystem: subsystem, category: "simple nse")
}

func log(_ message: String) {
    Logger.simpleNSE.debug("\(message, privacy: .public)")
}

// TODO: add id to service and include in logs

final class SimpleNotificationService: UNNotificationServiceExtension {

    // MARK: - Types

    typealias ContentHandler = (UNNotificationContent) -> Void

    // MARK: - Properties

    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared

    // MARK: - Life cycle

    override init() {
        super.init()
    }

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping ContentHandler
    ) {
        guard #available(iOS 15, *) else {
            contentHandler(.debugMessageIfNeeded(message: "iOS 15 not available"))
            return
        }

        // TODO: maybe keep a reference to the task so we
        // can cancel it if the extension expires.
        Task {
            do {
                log("\(request.identifier): received request")
                let session = try Job(request: request)
                let content = try await session.execute()
                log("\(request.identifier): showing notification")
                contentHandler(content)
            } catch {
                let message = "\(request.identifier): failed with error: \(String(describing: error))"
                log(message)
                contentHandler(.debugMessageIfNeeded(message: message))
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        log("extension (\(self) is expiring")
        fatalError("not implemented")
    }

}
