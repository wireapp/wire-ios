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

public enum Logging: LoggerProtocol {

  public static var provider: LoggerProtocol?

  public func debug(
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    Self.provider?.debug(
      message,
      attributes: attributes
    )
  }

  public func info(
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    Self.provider?.info(
      message,
      attributes: attributes
    )
  }

  public func notice(
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    Self.provider?.notice(
      message,
      attributes: attributes
    )
  }

  public func warn(
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    Self.provider?.warn(
      message,
      attributes: attributes
    )
  }

  public func error(
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    Self.provider?.error(
      message,
      attributes: attributes
    )
  }

  public func critical(
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    Self.provider?.critical(
      message,
      attributes: attributes
    )
  }

}

public typealias LogAttributes = [String: Encodable]

public protocol LoggerProtocol {

  func debug(_ message: String, attributes: LogAttributes?)
  func info(_ message: String, attributes: LogAttributes?)
  func notice(_ message: String, attributes: LogAttributes?)
  func warn(_ message: String, attributes: LogAttributes?)
  func error(_ message: String, attributes: LogAttributes?)
  func critical(_ message: String, attributes: LogAttributes?)

}

public extension LoggerProtocol {

  func debug(
    tag: String,
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    var attrs = attributes ?? .init()
    attrs["tag"] = tag
    debug(message, attributes: attrs)
  }

  func info(
    tag: String,
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    var attrs = attributes ?? .init()
    attrs["tag"] = tag
    info(message, attributes: attrs)
  }

  func notice(
    tag: String,
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    var attrs = attributes ?? .init()
    attrs["tag"] = tag
    notice(message, attributes: attrs)
  }

  func warn(
    tag: String,
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    var attrs = attributes ?? .init()
    attrs["tag"] = tag
    warn(message, attributes: attrs)
  }

  func error(
    tag: String,
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    var attrs = attributes ?? .init()
    attrs["tag"] = tag
    error(message, attributes: attrs)
  }

  func critical(
    tag: String,
    _ message: String,
    attributes: LogAttributes? = nil
  ) {
    var attrs = attributes ?? .init()
    attrs["tag"] = tag
    critical(message, attributes: attrs)
  }

}
