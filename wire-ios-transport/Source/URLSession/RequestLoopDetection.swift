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

// MARK: - RequestLoopDetection

/// Monitors the REST requests that are sent over the network
/// to detect suspicious request loops
@objcMembers
public final class RequestLoopDetection: NSObject {
    /// After this time, requests are purged from the list
    static let decayTimer: TimeInterval = 60 // 1 minute

    /// Repetition warning trigger threshold
    /// If a request is repeated more than this number of times,
    /// it will trigger a warning
    static let repetitionTriggerThreshold = 20

    /// Hard limit of URLs to keep in the history
    static let historyLimit = 120

    /// List of requests
    private(set) var recordedRequests: [IdentifierDate] = []

    /// Trigger that will be invoked when a loop is detected
    /// The URL passed is the URL that created the loop
    private let triggerCallback: (String) -> Void

    public init(triggerCallback: @escaping (String) -> Void) {
        self.triggerCallback = triggerCallback
    }

    // MARK: - Loop detection

    /// Resets the detector, discarding all recorder requests
    public func reset() {
        recordedRequests = []
    }

    public func recordRequest(path: String, contentHint: String, date: Date?) {
        purgeOldRequests()

        if recordedRequests.count == Self.historyLimit {
            recordedRequests.remove(at: 0) // note, this would be more efficient with linked list
        }

        if isPathExcluded(path) {
            return
        }

        let identifier = IdentifierDate(path: path, contentHint: contentHint, date: date ?? Date())
        insert(identifier: identifier)

        triggerIfTooMany(identifier: identifier)
    }

    /// Removes requests that are too old from the recorded requests
    private func purgeOldRequests() {
        let purgeDate = Date(timeIntervalSinceNow: -Self.decayTimer)
        if let firstNonTooOldIndex = recordedRequests.firstIndex(where: {
            $0.date > purgeDate
        }) {
            recordedRequests
                .removeFirst(firstNonTooOldIndex) // note, this would be more efficient with linked list
        } else {
            // all requests are old, kill them
            reset()
        }
    }

    /// Insert request in the right date order in the array.
    /// - note: Complexity: O(n). Could be made O(log(n)) with
    /// binary search
    private func insert(identifier: IdentifierDate) {
        if identifier.date.timeIntervalSinceNow < -type(of: self).decayTimer {
            return // not even adding, this is too old
        }

        // I assume most (if not all) request are inserted in ascending order, so I will
        // search backwards
        var insertionIndex = 0
        for i in (0 ..< recordedRequests.count).lazy.reversed() where recordedRequests[i].date < identifier.date {
            insertionIndex = i + 1
            break
        }
        recordedRequests.insert(identifier, at: insertionIndex)
    }

    /// Check if there are too many occurrences of a given identifier
    private func triggerIfTooMany(identifier: IdentifierDate) {
        // this could be slightly faster as we don't need to count, just stop after we found N
        // (maybe there are N+1000 entries and we don't need to go through the additional 1000)
        let count = recordedRequests
            .filter { $0.identifier == identifier.identifier }
            .count

        if count >= Self.repetitionTriggerThreshold {
            triggerCallback(identifier.path)
            recordedRequests = recordedRequests.filter { $0.identifier != identifier.identifier }
        }
    }

    func isPathExcluded(_ path: String) -> Bool {
        guard let urlComponents = URLComponents(string: path) else {
            return false
        }

        if urlComponents.path.hasSuffix("/typing") == true {
            return true
        }

        if urlComponents.path.hasSuffix("/search/contacts") {
            if  let query = urlComponents.queryItems?.first(where: { $0.name == "q" }), let value = query.value {
                return value.isEmpty
            }
        }

        return false
    }
}

// MARK: - IdentifierDate

struct IdentifierDate {
    let identifier: String
    let date: Date
    let path: String

    init(path: String, contentHint: String, date: Date) {
        self.identifier = "\(path)[\(contentHint)]"
        self.date = date
        self.path = path
    }
}
