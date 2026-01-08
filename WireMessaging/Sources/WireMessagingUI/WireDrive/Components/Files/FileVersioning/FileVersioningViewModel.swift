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

import Combine
import Foundation
import SwiftUI
import WireFoundation
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

struct FileVersionItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
}

/// View model for the `FileVersioningView`.
@MainActor
final class FileVersioningViewModel: ObservableObject {

    struct VersionModel: Identifiable, Hashable {
        var id: Self { self }
        let header: String
        var items: [FileVersionItem]
    }

    let name: String

    private let nodeID: UUID
    private let eTag: String?
    private let fetchNodeVersionsUseCase: any WireCellsFetchNodeVersionsUseCaseProtocol
    private let restoreNodeVersionUseCase: any WireCellsRestoreNodeVersionUseCaseProtocol
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let accentColorProvider: () -> WireAccentColor
    private var subscriptions = Set<AnyCancellable>()

    var accentColor: WireAccentColor {
        accentColorProvider()
    }

    enum State {
        case loading
        case received([VersionModel])
        case restoringVersion

        var versions: [VersionModel] {
            switch self {
            case let .received(sections):
                sections
            default:
                []
            }
        }
    }

    @Published var viewingURL: URL?
    @Published var alert: AlertModel?
    @Published var state: State

    typealias DateFormattingContext = (
        locale: Locale,
        calendar: Calendar,
        timeZone: TimeZone
    )

    let context: DateFormattingContext

    init(
        nodeID: UUID,
        name: String,
        eTag: String?,
        context: DateFormattingContext = (
            Locale.autoupdatingCurrent,
            Calendar.autoupdatingCurrent,
            TimeZone.autoupdatingCurrent
        ),
        fetchNodeVersionsUseCase: any WireCellsFetchNodeVersionsUseCaseProtocol,
        restoreNodeVersionUseCase: any WireCellsRestoreNodeVersionUseCaseProtocol,
        getAssetUseCase: WireCellsGetAssetUseCase,
        accentColorProvider: @escaping () -> WireAccentColor
    ) {
        self.nodeID = nodeID
        self.name = name
        self.eTag = eTag
        self.context = context
        self.fetchNodeVersionsUseCase = fetchNodeVersionsUseCase
        self.restoreNodeVersionUseCase = restoreNodeVersionUseCase
        self.getAssetUseCase = getAssetUseCase
        self.accentColorProvider = accentColorProvider
        self.state = .loading
    }

    func startPolling() {
        Timer.publish(every: .thirtySeconds, on: .main, in: .common)
            .autoconnect()
            .handleEvents(receiveSubscription: { [weak self] _ in
                Task { await self?.fetch() }
            })
            .sink { [weak self] _ in
                Task { await self?.fetch() }
            }.store(in: &subscriptions)
    }

    func itemViewModel(sectionIndex: Int, itemIndex: Int) -> FileVersionItemViewModel {
        FileVersionItemViewModel(
            nodeID: nodeID,
            item: state.versions[sectionIndex].items[itemIndex],
            accentColor: accentColor,
            onRestore: { [weak self] item in
                Task { await self?.restore(item: item) }
            }
        )
    }

    func fetch() async {
        do {
            let response = try await fetchNodeVersionsUseCase.invoke(
                nodeID: nodeID
            )

            state = .received(makeVersionModels(from: response))

        } catch {
            state = .received([])
            alert = .unknownError
        }
    }

    // MARK: - Private

    private func restore(item: FileVersionItem) async {
        state = .restoringVersion

        try? await Task.sleep(for: .seconds(2))

        do {
            try await restoreNodeVersionUseCase.invoke(
                nodeID: nodeID,
                versionID: item.id
            )

            Task {
                await fetch()
            }

            viewingURL = try await getAssetUseCase.invoke(nodeID: nodeID, eTag: eTag)

        } catch {
            alert = AlertModel(
                title: Strings.FilesVersioning.restoreFailureAlertTitle,
                message: Strings.FilesVersioning.restoreFailureAlertMessage,
                actionsButtons: [
                    .init(title: Strings.FilesVersioning.retry, role: .cancel) { [weak self] in
                        await self?.restore(item: item)
                    },
                    .init(title: L10n.Localizable.General.cancel, role: .none) { [weak self] in await self?.fetch() }
                ]
            )
        }
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

        // first item from the first section is the most recent file
        guard var firstSection = sections.first,
              var firstItem = firstSection.items.first else { return sections }

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
            let calendar = context.calendar
            return calendar.startOfDay(for: date)
        }
    }

    private func sortVersionsByTime(
        _ arg1: WireCellsNodeVersion,
        _ arg2: WireCellsNodeVersion
    ) -> Bool {
        let calendar = context.calendar
        let date1 = arg1.modified ?? Date.distantPast
        let components1 = calendar.dateComponents([.hour, .minute, .second], from: date1)
        let compared1 = calendar.date(from: components1)

        let date2 = arg2.modified ?? Date.distantPast
        let components2 = calendar.dateComponents([.hour, .minute, .second], from: date2)
        let compared2 = calendar.date(from: components2)

        guard let compared1, let compared2 else { return false }

        return compared1 > compared2
    }

    private func makeVersionItem(version: WireCellsNodeVersion) -> FileVersionItem {
        let title = version.modified.map(formattedItemDate) ?? ""
        let subtitle = [version.ownerName, version.size.map(formattedFileSize)]
            .compactMap(\.self)
            .joined(separator: " · ")

        return FileVersionItem(
            id: version.id,
            title: title,
            subtitle: subtitle,
        )
    }

    // MARK: - Formatters

    private func formattedHeaderDate(_ date: Date) -> String {
        let style = Date.FormatStyle(
            locale: context.locale,
            calendar: context.calendar,
            timeZone: context.timeZone
        )
        .weekday(.wide)
        .month(.abbreviated)
        .day()
        .year()

        return date.formatted(style)
    }

    private func formattedItemDate(_ date: Date) -> String {
        let style = Date.FormatStyle(
            locale: context.locale,
            calendar: context.calendar,
            timeZone: context.timeZone
        )
        .hour(.defaultDigits(amPM: .abbreviated))
        .minute()

        return date.formatted(style)
    }

    func formattedFileSize(size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}
