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

final class DatabaseStatisticsViewModel {

    // MARK: - Types

    struct AssetSummary {
        let size: Int64
        let isImage: Bool
        let isFile: Bool
        let isVideo: Bool
        let isAudio: Bool
    }

    struct Statistics {
        let databaseVersion: String
        let conversationsCount: Int
        let invalidConversationsCount: Int
        let usersCount: Int
        let messagesCount: Int
        let assets: [AssetSummary]
    }

    struct Row: Equatable {
        let title: String
        let contents: String
    }

    struct DisplayState: Equatable {
        let rows: [Row]
        let isLoading: Bool
    }

    // MARK: - Properties

    private let byteCountFormatter: (Int64) -> String
    private(set) var displayState = DisplayState(rows: [], isLoading: true)

    // MARK: - Initialization

    init(byteCountFormatter: @escaping (Int64) -> String = DatabaseStatisticsViewModel.formatByteCount) {
        self.byteCountFormatter = byteCountFormatter
    }

    // MARK: - Methods

    @discardableResult
    func startLoading() -> DisplayState {
        displayState = DisplayState(rows: [], isLoading: true)
        return displayState
    }

    @discardableResult
    func update(with statistics: Statistics) -> DisplayState {
        displayState = DisplayState(
            rows: makeRows(from: statistics),
            isLoading: false
        )
        return displayState
    }

    @discardableResult
    func update(with error: Error) -> DisplayState {
        displayState = DisplayState(
            rows: [
                Row(title: "Error", contents: error.localizedDescription)
            ],
            isLoading: false
        )
        return displayState
    }

    private func makeRows(from statistics: Statistics) -> [Row] {
        var rows = [
            Row(title: "Version", contents: statistics.databaseVersion),
            Row(title: "Number of conversations", contents: "\(statistics.conversationsCount)"),
            Row(title: "   Invalid", contents: "\(statistics.invalidConversationsCount)"),
            Row(title: "Number of users", contents: "\(statistics.usersCount)"),
            Row(title: "Number of messages", contents: "\(statistics.messagesCount)"),
            Row(title: "Asset messages:", contents: "")
        ]

        rows.append(contentsOf: [
            assetSizeRow(from: statistics.assets, title: "   Total", filter: { _ in true }),
            assetSizeRow(from: statistics.assets, title: "   Images", filter: \.isImage),
            assetSizeRow(from: statistics.assets, title: "   Files", filter: \.isFile),
            assetSizeRow(from: statistics.assets, title: "   Video", filter: \.isVideo),
            assetSizeRow(from: statistics.assets, title: "   Audio", filter: \.isAudio)
        ])

        return rows
    }

    private func assetSizeRow(
        from assets: [AssetSummary],
        title: String,
        filter: (AssetSummary) -> Bool
    ) -> Row {
        let filteredAssets = assets.filter(filter)
        let size = filteredAssets.reduce(0) { size, asset in
            size + asset.size
        }
        let titleWithCount = filteredAssets.isEmpty ? title : "\(title) (\(filteredAssets.count))"

        return Row(
            title: titleWithCount,
            contents: byteCountFormatter(size)
        )
    }

    private static func formatByteCount(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
