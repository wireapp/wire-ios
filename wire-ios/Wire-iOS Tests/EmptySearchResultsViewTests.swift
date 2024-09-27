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

import WireDesign
import WireTestingPackage
import XCTest
@testable import Wire

final class EmptySearchResultsViewTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: EmptySearchResultsView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = setupEmptySearchResultsView(
            isSelfUserAdmin: false,
            isFederationEnabled: false,
            searchingForServices: false,
            hasFilter: true
        )
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testNoResultsForUsers() {
        snapshotHelper.verify(matching: sut)
    }

    func testNoResultsForUsers_WhenFederationIsEnabled() {
        // GIVEN && WHEN
        sut = setupEmptySearchResultsView(
            isSelfUserAdmin: false,
            isFederationEnabled: true,
            searchingForServices: false,
            hasFilter: true
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testNoResultsForUsers_WhenEveryoneHaveBeenAdded() {
        // GIVEN && WHEN
        sut = setupEmptySearchResultsView(
            isSelfUserAdmin: false,
            isFederationEnabled: false,
            searchingForServices: false,
            hasFilter: false
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testNoResultsForServices() {
        // GIVEN && WHEN
        sut = setupEmptySearchResultsView(
            isSelfUserAdmin: false,
            isFederationEnabled: false,
            searchingForServices: true,
            hasFilter: true
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testServicesNotEnabled() {
        // GIVEN && WHEN
        sut = setupEmptySearchResultsView(
            isSelfUserAdmin: false,
            isFederationEnabled: false,
            searchingForServices: true,
            hasFilter: false
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testServicesNotEnabled_WhenAdmin() {
        // GIVEN && WHEN
        sut = setupEmptySearchResultsView(
            isSelfUserAdmin: true,
            isFederationEnabled: false,
            searchingForServices: true,
            hasFilter: false
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Helpers

    func setupEmptySearchResultsView(
        isSelfUserAdmin: Bool,
        isFederationEnabled: Bool,
        searchingForServices: Bool,
        hasFilter: Bool
    ) -> EmptySearchResultsView {
        let sut = EmptySearchResultsView(
            isSelfUserAdmin: isSelfUserAdmin,
            isFederationEnabled: isFederationEnabled
        )
        sut.overrideUserInterfaceStyle = .dark
        sut.updateStatus(
            searchingForServices: searchingForServices,
            hasFilter: hasFilter
        )
        configureBounds(for: sut)

        return sut
    }

    func configureBounds(for view: UIView) {
        view.bounds.size = view.systemLayoutSizeFitting(
            CGSize(width: 375, height: 600),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }
}
