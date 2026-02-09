//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public extension WireLogger {

    func measureTime<T>(
        label: String,
        durationKey: LogAttributesKey = .syncDuration,
        attributes: LogAttributes = [:],
        block: () async throws -> T
    ) async throws -> T {
        let context = measureTimeStart(label: label, durationKey: durationKey, attributes: attributes)
        let result = try await block()
        measureTimeEnd(context: context)
        return result
    }

    func measureTime<T, E: Error>(
        label: String,
        durationKey: LogAttributesKey = .syncDuration,
        attributes: LogAttributes = [:],
        block: () throws(E) -> T
    ) throws(E) -> T {
        let context = measureTimeStart(label: label, durationKey: durationKey, attributes: attributes)
        let result = try block()
        measureTimeEnd(context: context)
        return result
    }

    // MARK: - Helpers

    private struct Context {
        let start: Date
        let label: String
        let durationKey: LogAttributesKey
        let attributes: LogAttributes
    }

    private func measureTimeStart(
        label: String,
        durationKey: LogAttributesKey,
        attributes: LogAttributes
    ) -> Context {
        let startMessage = "starting \(label)"
        info(startMessage, attributes: attributes)

        return Context(
            start: Date.now,
            label: label,
            durationKey: durationKey,
            attributes: attributes
        )
    }

    private func measureTimeEnd(context: Context) {
        let durationInSeconds = context.start.timeIntervalSinceNow.magnitude
        var updatedAttributes = context.attributes
        let formattedDuration = String(format: "%.2f", durationInSeconds)
        updatedAttributes[context.durationKey] = formattedDuration
        let completedMessage = "completed \(context.label)"
        info(completedMessage, attributes: updatedAttributes)
    }

}
