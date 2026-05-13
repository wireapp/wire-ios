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

import XCTest

@testable import Wire

final class DatabaseStatisticsViewModelTests: XCTestCase {

    private var sut: DatabaseStatisticsViewModel!

    override func setUp() {
        super.setUp()
        sut = DatabaseStatisticsViewModel(byteCountFormatter: { "\($0) B" })
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testStartLoadingClearsRowsAndShowsLoading() {
        // GIVEN
        _ = sut.update(with: makeStatistics())

        // WHEN
        let displayState = sut.startLoading()

        // THEN
        XCTAssertEqual(displayState, DatabaseStatisticsViewModel.DisplayState(rows: [], isLoading: true))
    }

    func testUpdateWithStatisticsBuildsRowsAndFormatsAssetGroups() {
        // WHEN
        let displayState = sut.update(
            with: makeStatistics(
                assets: [
                    DatabaseStatisticsViewModel.AssetSummary(
                        size: 10,
                        isImage: true,
                        isFile: false,
                        isVideo: false,
                        isAudio: false
                    ),
                    DatabaseStatisticsViewModel.AssetSummary(
                        size: 20,
                        isImage: false,
                        isFile: true,
                        isVideo: false,
                        isAudio: true
                    )
                ]
            )
        )

        // THEN
        XCTAssertEqual(
            displayState,
            DatabaseStatisticsViewModel.DisplayState(
                rows: [
                    .init(title: "Version", contents: "model-v1"),
                    .init(title: "Number of conversations", contents: "4"),
                    .init(title: "   Invalid", contents: "1"),
                    .init(title: "Number of users", contents: "8"),
                    .init(title: "Number of messages", contents: "16"),
                    .init(title: "Asset messages:", contents: ""),
                    .init(title: "   Total (2)", contents: "30 B"),
                    .init(title: "   Images (1)", contents: "10 B"),
                    .init(title: "   Files (1)", contents: "20 B"),
                    .init(title: "   Video", contents: "0 B"),
                    .init(title: "   Audio (1)", contents: "20 B")
                ],
                isLoading: false
            )
        )
    }

    func testUpdateWithErrorShowsErrorRowAndHidesLoading() {
        struct AnyError: LocalizedError {
            var errorDescription: String? { "Failed to load" }
        }

        // WHEN
        let displayState = sut.update(with: AnyError())

        // THEN
        XCTAssertEqual(
            displayState,
            DatabaseStatisticsViewModel.DisplayState(
                rows: [
                    .init(title: "Error", contents: "Failed to load")
                ],
                isLoading: false
            )
        )
    }

    private func makeStatistics(
        assets: [DatabaseStatisticsViewModel.AssetSummary] = []
    ) -> DatabaseStatisticsViewModel.Statistics {
        DatabaseStatisticsViewModel.Statistics(
            databaseVersion: "model-v1",
            conversationsCount: 4,
            invalidConversationsCount: 1,
            usersCount: 8,
            messagesCount: 16,
            assets: assets
        )
    }
}
