//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import SwiftUI
import WireFoundation
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

/// View model for the `FileVersioningView`.
@MainActor
final class FileVersioningViewModel: ObservableObject {

    struct VersionModel: Identifiable {
        let id = UUID()
        let header: String
        var items: [VersionItem]

        struct VersionItem: Identifiable {
            let id: UUID
            let title: String
            let subtitle: String
        }
    }

    private let nodeID: UUID
    private let fetchNodeVersionsUseCase: any WireCellsFetchNodeVersionsUseCaseProtocol
    private let accentColorProvider: () -> WireAccentColor

    var accentColor: WireAccentColor {
        accentColorProvider()
    }

    @Published var versions: [VersionModel] = []
    @Published var isLoading = false
    @Published var showError = false

    init(
        nodeID: UUID,
        fetchNodeVersionsUseCase: any WireCellsFetchNodeVersionsUseCaseProtocol,
        accentColorProvider: @escaping () -> WireAccentColor
    ) {
        self.nodeID = nodeID
        self.fetchNodeVersionsUseCase = fetchNodeVersionsUseCase
        self.accentColorProvider = accentColorProvider
    }

    func fetch(isRefreshing: Bool = false) async {
        if !isRefreshing { isLoading = true }
        defer { isLoading = false }

        do {
            let response = try await fetchNodeVersionsUseCase.invoke(
                nodeID: nodeID
            )

            versions = makeVersionModels(from: response)

        } catch {
            showError = true
        }
    }

    func restore() async {
        // TODO: Implement me
    }

    func download() async {
        // TODO: Implement me
    }

    private func makeVersionModels(from versions: [WireCellsNodeVersion]) -> [VersionModel] {
        let groupedVersions = groupedVersionsByDay(versions)
            .sorted(by: { $0.key > $1.key })

        var sections = groupedVersions.compactMap { date, versionsForDate in
            let items = versionsForDate
                .sorted(by: sortVersionsByTime)
                .map(makeVersionItem)

            return VersionModel(
                header: formattedHeaderDate(date),
                items: items
            )

        }
        
        guard var firstSection = sections.first,
              var firstItem = firstSection.items.first
        else {
            return sections
        }

        firstItem = .init(
            id: firstItem.id,
            title: firstItem.title + " " + Strings.FilesVersioning.currentFile,
            subtitle: firstItem.subtitle
        )

        firstSection.items[0] = firstItem
        sections[0] = firstSection
        
        return sections
    }
    
    // MARK: - Grouping & Sorting
    
    private func groupedVersionsByDay(
        _ versions: [WireCellsNodeVersion]
    ) -> [Date: [WireCellsNodeVersion]] {
        Dictionary(grouping: versions) { version in
            let date = version.modified ?? Date.distantPast
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            return Calendar.current.date(from: components) ?? .distantPast
        }
    }
    
    private func sortVersionsByTime(
        _ arg1: WireCellsNodeVersion,
        _ arg2: WireCellsNodeVersion
    ) -> Bool {
        let date1 = arg1.modified ?? Date.distantPast
        let components1 = Calendar.current.dateComponents([.hour, .minute, .second], from: date1)
        let compared1 = Calendar.current.date(from: components1)

        let date2 = arg2.modified ?? Date.distantPast
        let components2 = Calendar.current.dateComponents([.hour, .minute, .second], from: date2)
        let compared2 = Calendar.current.date(from: components2)

        guard let compared1, let compared2 else { return false }

        return compared1 > compared2
    }

    private func makeVersionItem(version: WireCellsNodeVersion) -> VersionModel.VersionItem {
        let title = version.modified.map(formattedItemDate) ?? ""
        let subtitle = (version.ownerName ?? "") + " · " + (version.size.map(formattedFileSize) ?? "")

        return VersionModel.VersionItem(
            id: version.id,
            title: title,
            subtitle: subtitle,
        )
    }

    // MARK: - Formatters

    private func formattedHeaderDate(_ date: Date) -> String {
        let style = Date.FormatStyle()
            .weekday(.wide)
            .month(.abbreviated)
            .day()
            .year()
        
        return date.formatted(style)
    }

    private func formattedItemDate(_ date: Date) -> String {
        let style = Date.FormatStyle()
            .hour(.defaultDigits(amPM: .abbreviated))
            .minute()
        
        return date.formatted(style)
    }
    
    func formattedFileSize(size: UInt64) -> String {
        let bytes = Double(size)

        if bytes < 1024 {
            return String(format: "%.0f B", bytes)
        } else if bytes < 1_048_576 {
            return String(format: "%.1f KB", bytes / 1024)
        } else if bytes < 1_073_741_824 {
            return String(format: "%.2f MB", bytes / 1_048_576)
        } else {
            return String(format: "%.2f GB", bytes / 1_073_741_824)
        }
    }
}
