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

import SwiftUI
import WireFoundation
import WireTestingPackage
import XCTest

@testable import WireCallingDomain
@testable import WireCallingDomainSupport
@testable import WireCallingUI

final class MemberSelectionViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - Loading State

    @MainActor
    func testLoadingStateColorSchemeVariants() {
        verifyColorSchemeVariants(viewModel: makeLoadingViewModel(), testName: #function)
    }

    @MainActor
    func testLoadingStateDynamicTypeVariants() {
        verifyDynamicTypeVariants(viewModel: makeLoadingViewModel(), testName: #function)
    }

    // MARK: - Empty State

    @MainActor
    func testEmptyStateColorSchemeVariants() async {
        let viewModel = await makeSettledViewModel(searchResults: [])
        verifyColorSchemeVariants(viewModel: viewModel, testName: #function)
    }

    @MainActor
    func testEmptyStateDynamicTypeVariants() async {
        let viewModel = await makeSettledViewModel(searchResults: [])
        verifyDynamicTypeVariants(viewModel: viewModel, testName: #function)
    }

    // MARK: - Populated State

    @MainActor
    func testPopulatedStateColorSchemeVariants() async {
        let viewModel = await makeSettledViewModel(searchResults: .mock)
        verifyColorSchemeVariants(viewModel: viewModel, testName: #function)
    }

    @MainActor
    func testPopulatedStateDynamicTypeVariants() async {
        let viewModel = await makeSettledViewModel(searchResults: .mock)
        verifyDynamicTypeVariants(viewModel: viewModel, testName: #function)
    }

    // MARK: - Verification helpers

    @MainActor
    private func verifyColorSchemeVariants(
        viewModel: MemberSelectionViewModel,
        testName: String = #function
    ) {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            MemberSelectionView(viewModel: viewModel)
        }
        .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", testName: testName)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", testName: testName)
    }

    @MainActor
    private func verifyDynamicTypeVariants(
        viewModel: MemberSelectionViewModel,
        testName: String = #function
    ) {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            MemberSelectionView(viewModel: viewModel)
        }
        .frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)",
                    testName: testName
                )
        }
    }

    // MARK: - View model factories

    /// Builds a view model whose initial search resolves to `searchResults` and
    /// waits for the init-time async search to complete before returning.
    @MainActor
    private func makeSettledViewModel(searchResults: [MeetingMember]) async -> MemberSelectionViewModel {
        let useCase = SearchMembersUseCaseProtocolMock()
        useCase.invokeQueryStringMeetingMemberReturnValue = searchResults
        let viewModel = MemberSelectionViewModel(source: useCase)
        while viewModel.isSearching {
            await Task.yield()
        }
        return viewModel
    }

    /// Builds a view model whose initial search never returns so the view
    /// stays in the loading state when snapshotted.
    @MainActor
    private func makeLoadingViewModel() -> MemberSelectionViewModel {
        let useCase = SearchMembersUseCaseProtocolMock()
        useCase.invokeQueryStringMeetingMemberClosure = { _ in
            try? await Task.sleep(for: .seconds(60))
            return []
        }
        return MemberSelectionViewModel(source: useCase)
    }
}

// MARK: - Mock fixtures

private extension [MeetingMember] {
    static var mock: Self {
        [
            .init(name: "Martin Koch-Johansen", handle: "username", isSelfUser: true),
            .init(name: "Olga Heaney", handle: "username"),
            .init(name: "Margarete Springer", handle: "username"),
            .init(name: "Lorenzo Schmeler", handle: ""),
            .init(name: "Jaqueline Olaho", handle: ""),
            .init(name: "Katie Armstrong", handle: "username"),
            .init(name: "Zachary Ratke", handle: "username"),
            .init(name: "Marco Weissnat", handle: "username"),
            .init(name: "Deborah Schoen", handle: "username")
        ]
    }
}

private extension MeetingMember {

    init(
        name: String,
        handle: String,
        isSelfUser: Bool = false
    ) {
        let initials = name
            .split(separator: " ")
            .compactMap(\.first)
            .prefix(2)
            .map(String.init)
            .joined()
            .uppercased()

        self.init(
            qualifiedID: QualifiedID(id: UUID(), domain: ""),
            name: name,
            handle: handle,
            isSelfUser: isSelfUser,
            initials: initials,
            accentColor: .random,
            avatarImageData: nil
        )
    }

}
