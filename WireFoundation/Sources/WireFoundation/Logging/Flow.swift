//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

/// A `Flow` is a structured log class that reports the progress
/// of a particular flow of code, marking the start, middle, and end
/// of the flow.
///
/// It reports the flow events via a `WireLogger` instance using a specified tag.

open class Flow {

  // MARK: - Properties

  /// The name used to identify the flow in logs.

  public let name: String

  private let logger: WireLogger

  // MARK: - Life cycle

  /// Create a new flow.
  ///
  /// - Parameters:
  ///   - tag: The log tag, can be used to group several different flows.
  ///   - name: The name of the flow, used to group several events of a single flow.

  public init(
    tag: String,
    name: String
  ) {
    self.name = name
    logger = WireLogger(tag: tag)
  }

  // MARK: - Methods

  /// Report the start of the flow.

  public func start() {
    logger.info(FlowLog(name: name, event: .init(type: .start, description: nil, outcome: .success)))
  }

  /// Report a checkpoint in the flow.
  ///
  /// - Parameters:
  ///   - description: A short single line string describing a point of interest.

    public func checkpoint(description: any LogConvertible) {
      logger.info(FlowLog(name: name, event: .init(type: .checkpoint, description: description.logDescription, outcome: .success)))
  }

  /// Report a successful end to the flow.

  public func succeed() {
      logger.info(FlowLog(name: name, event: .init(type: .end, description: nil, outcome: .success)))
  }

  /// Report a failed end to the flow.
  ///
  /// - Parameters:
  ///   - error: The failure reason.

    public func fail(_ error: any Error) {
      logger.error(FlowLog(name: name, event: .init(type: .end, description: String(describing: error), outcome: .failure)))
  }

  /// Report a failed end to the flow.
  ///
  /// - Parameters:
  ///   - reason: The failure reason.

    public func fail(_ reason: any LogConvertible) {
      logger.error(FlowLog(name: name, event: .init(type: .end, description: reason.logDescription, outcome: .failure)))
  }

  struct GenericError: Error {

    let reason: String

  }

}

struct FlowLog: LogConvertible, Encodable {

    let name: String
    let event: Event

    var logDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self) else {
            return "FLOW: \(name) ENCODING ERROR"
        }

        let string = String(decoding: data, as: UTF8.self)
        return "FLOW: \(string)"
    }
}

extension FlowLog {
  struct Event: Encodable {
      enum StepType: String, Encodable {
          case start
          case checkpoint
          case end
      }

      enum StepOutcome: String, Encodable {
          case failure
          case success
      }

      var type: StepType
      var description: String?
      var outcome: StepOutcome
  }
}

public extension Flow {
    static var createGroup: Flow {
        Flow(tag: WireLogger.conversation.tag, name: "CreateGroup")
    }
    static var addParticipants: Flow {
        Flow(tag: WireLogger.conversation.tag, name: "AddParticipants")
    }
}
