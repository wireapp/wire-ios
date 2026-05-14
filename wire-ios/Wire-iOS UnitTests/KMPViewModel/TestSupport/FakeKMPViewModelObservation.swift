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

@testable import Wire

@MainActor
final class FakeKMPViewModelObservation: KMPViewModelObservation {

    private let onCancel: () -> Void
    private(set) var cancelCallsCount = 0

    var isCancelled: Bool {
        cancelCallsCount > 0
    }

    init(onCancel: @escaping () -> Void = {}) {
        self.onCancel = onCancel
    }

    func cancel() {
        cancelCallsCount += 1

        guard cancelCallsCount == 1 else { return }
        onCancel()
    }
}
