//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public struct WireLogger: LoggerProtocol {

  public static var provider: LoggerProtocol? = AggregatedLogger(loggers: [SystemLogger()])

  public let tag: String

  public init(tag: String = "") {
    self.tag = tag
  }

  public func debug(
    _ message: LogConvertible,
    attributes: LogAttributes? = nil
  ) {
    guard shouldLogMessage(message) else { return }
    log(level: .debug, message: message, attributes: attributes)
  }

  public func info(
    _ message: LogConvertible,
    attributes: LogAttributes? = nil
  ) {
    guard shouldLogMessage(message) else { return }
    log(level: .info, message: message, attributes: attributes)
  }

  public func notice(
    _ message: LogConvertible,
    attributes: LogAttributes? = nil
  ) {
    guard shouldLogMessage(message) else { return }
    log(level: .notice, message: message, attributes: attributes)
  }

  public func warn(
    _ message: LogConvertible,
    attributes: LogAttributes? = nil
  ) {
    guard shouldLogMessage(message) else { return }
    log(level: .warn, message: message, attributes: attributes)
  }

  public func error(
    _ message: LogConvertible,
    attributes: LogAttributes? = nil
  ) {
    guard shouldLogMessage(message) else { return }
    log(level: .error, message: message, attributes: attributes)
  }

  public func critical(
    _ message: LogConvertible,
    attributes: LogAttributes? = nil
  ) {
    guard shouldLogMessage(message) else { return }
    log(level: .critical, message: message, attributes: attributes)
  }

  private func shouldLogMessage(_ message: LogConvertible) -> Bool {
    return Self.provider != nil && !message.logDescription.isEmpty
  }

  private func log(
    level: LogLevel,
    message: LogConvertible,
    attributes: LogAttributes? = nil
  ) {
    var attributes = attributes ?? .init()

    if !tag.isEmpty {
      attributes["tag"] = tag
    }

    switch level {
    case .debug:
      Self.provider?.debug(message, attributes: attributes)

    case .info:
      Self.provider?.info(message, attributes: attributes)

    case .notice:
      Self.provider?.notice(message, attributes: attributes)

    case .warn:
      Self.provider?.warn(message, attributes: attributes)

    case .error:
      Self.provider?.error(message, attributes: attributes)

    case .critical:
      Self.provider?.critical(message, attributes: attributes)
    }
  }

  private enum LogLevel {

    case debug
    case info
    case notice
    case warn
    case error
    case critical

  }

}

public typealias LogAttributes = [String: Encodable]

public extension LogAttributes {
    static var safePublic = ["public": true]
}

public protocol LoggerProtocol {

  func debug(_ message: LogConvertible, attributes: LogAttributes?)
  func info(_ message: LogConvertible, attributes: LogAttributes?)
  func notice(_ message: LogConvertible, attributes: LogAttributes?)
  func warn(_ message: LogConvertible, attributes: LogAttributes?)
  func error(_ message: LogConvertible, attributes: LogAttributes?)
  func critical(_ message: LogConvertible, attributes: LogAttributes?)

  func persist(fileDestination: FileLoggerDestination) async
}

extension LoggerProtocol {

    public func persist(fileDestination: FileLoggerDestination) async {}
}

public protocol LogConvertible {

  var logDescription: String { get }

}

extension String: LogConvertible {

  public var logDescription: String {
    return self
  }

}

public extension WireLogger {

    static let proteus = WireLogger(tag: "proteus")
    static let shareExtension = WireLogger(tag: "share-extension")
    static let notifications = WireLogger(tag: "notifications")
    static let calling = WireLogger(tag: "calling")
    static let messaging = WireLogger(tag: "messaging")
    static let backend = WireLogger(tag: "backend")
    static let ear = WireLogger(tag: "encryption-at-rest")
    static let keychain = WireLogger(tag: "keychain")
    static let mls = WireLogger(tag: "mls")
    static let coreCrypto = WireLogger(tag: "core-crypto")
    static let environment = WireLogger(tag: "environment")
    static let updateEvent = WireLogger(tag: "update-event")
    static let performance = WireLogger(tag: "performance")
    static let badgeCount = WireLogger(tag: "badge-count")
    static let userClient = WireLogger(tag: "user-client")
    static let localStorage = WireLogger(tag: "local-storage")
    static let conversation = WireLogger(tag: "conversation")
    static let authentication = WireLogger(tag: "authentication")
    static let session = WireLogger(tag: "session")
    static let e2ei = WireLogger(tag: "end-to-end-identity")
    static let sync = WireLogger(tag: "sync")
    static let system = WireLogger(tag: "system")
    static let featureConfigs = WireLogger(tag: "feature-configurations")
}

class WireLoggerObjc: NSObject {

    @objc
    static func assertionDumpLog(_ message: String) {
        WireLogger.system.error(message, attributes: .safePublic)
    }

}
