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

enum ImportEventsError: Error {
    case fileNotFound(String)
}

class ImportEventsURLActionProcessor: URLActionProcessor {

    private let eventProcessor: UpdateEventProcessor

    init(eventProcessor: UpdateEventProcessor) {
        self.eventProcessor = eventProcessor
    }

    func process(urlAction: URLAction, delegate: (any PresentationDelegate)?) {
        guard case .importEvents = urlAction else {
            return
        }

        Task {
            do {
                try await handleImportEvents(urlAction: urlAction, delegate: delegate)
                await MainActor.run {
                    delegate?.completedURLAction(urlAction)
                }
            } catch {
                await MainActor.run {
                    delegate?.failedToPerformAction(urlAction, error: error)
                }
            }
        }
    }

    private func handleImportEvents(
        urlAction: URLAction,
        delegate: PresentationDelegate?
    ) async throws {
        let eventsFile = FileManager.default.temporaryDirectory.appendingPathComponent("events", conformingTo: .plainText)

        guard let eventsData = FileManager.default.contents(atPath: eventsFile.path) else {
            delegate?.failedToPerformAction(urlAction, error: ImportEventsError.fileNotFound(eventsFile.path))
            return
        }

        let events = updateEventsFromJSON(eventsData)
        let start = DispatchTime.now()
        try await eventProcessor.processEvents(events)
        let end = DispatchTime.now()
        let elapsedTimeInMilliSeconds = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000

        WireLogger.eventProcessing.info("It took \(elapsedTimeInMilliSeconds) ms to import \(events.count) event(s)")
    }

    private func updateEventsFromJSON(_ eventsData: Data) -> [ZMUpdateEvent] {
        let eventsRaw = String(decoding: eventsData, as: UTF8.self)
        let eventsDicts = ((eventsRaw as ZMTransportData)
            .asDictionary() as? NSDictionary)?
            .optionalArray(forKey: "notifications")?
            .compactMap { $0 as? ZMTransportData }

        guard let events = eventsDicts?.compactMap({
            ZMUpdateEvent.eventsArray(from: $0, source: .download)
        }) else {
            return []
        }

        return Array(events.joined())
    }

}
