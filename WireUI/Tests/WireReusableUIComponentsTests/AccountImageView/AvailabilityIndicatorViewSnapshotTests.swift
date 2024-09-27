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

import WireTestingPackage
import XCTest
@testable import WireReusableUIComponents

// MARK: - AvailabilityIndicatorViewSnapshotTests

final class AvailabilityIndicatorViewSnapshotTests: XCTestCase {
    // MARK: Internal

    typealias SUT = AvailabilityIndicatorView

    override func setUp() async throws {
        (sut, container) = await MainActor.run {
            let container = UIView(frame: .init(origin: .zero, size: .init(width: 26, height: 26)))
            let sut = SUT(frame: .init(x: 3, y: 3, width: 20, height: 20))
            container.addSubview(sut)
            return (sut, container)
        }
        snapshotHelper = .init()
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    @MainActor
    func testAllAvailabilities() {
        for availability in Availability.allCases + [Availability?.none] {
            // Given
            sut.availability = availability
            let testName = if let availability { "\(availability)" } else { "none" }

            // Then
            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: container, named: "light", testName: testName)
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: container, named: "dark", testName: testName)
        }
    }

    // MARK: Private

    /// A container is needed because the availability indicator view has a border beyond its frame.
    private var container: UIView!
    private var sut: SUT!
    private var snapshotHelper: SnapshotHelper!
}

// MARK: - AvailabilityIndicatorView + Sendable

extension AvailabilityIndicatorView: Sendable {}
