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

import SnapshotTesting
import WireSyncEngine
import WireSyncEngineSupport
import WireTestingPackage
import WireTransport
import XCTest
@testable import Wire

final class MockOptionsViewModelConfiguration: ConversationGuestOptionsViewModelConfiguration {
    typealias SetHandler = (Bool, (Result<Void, Error>) -> Void) -> Void

    var allowGuests: Bool
    var guestLinkFeatureStatus: GuestLinkFeatureStatus
    var setAllowGuests: SetHandler?
    var allowGuestsChangedHandler: ((Bool) -> Void)?
    var guestLinkFeatureStatusChangedHandler: ((GuestLinkFeatureStatus) -> Void)?
    var linkResult: Result<(uri: String?, secured: Bool), Error>?
    var deleteResult: Result<Void, Error> = .success(())
    var createResult: Result<String, Error>?
    var isCodeEnabled = true
    var areGuestPresent = true
    var isConversationFromSelfTeam = true

    init(
        allowGuests: Bool,
        guestLinkFeatureStatus: GuestLinkFeatureStatus = .enabled,
        setAllowGuests: SetHandler? = nil
    ) {
        self.allowGuests = allowGuests
        self.guestLinkFeatureStatus = guestLinkFeatureStatus
        self.setAllowGuests = setAllowGuests
    }

    func setAllowGuests(_ allowGuests: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        setAllowGuests?(allowGuests, completion)
    }

    func fetchConversationLink(completion: @escaping (Result<(uri: String?, secured: Bool), Error>) -> Void) {
        linkResult.map(completion)
    }

    func deleteLink(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(deleteResult)
    }
}

// MARK: - ConversationOptionsViewControllerTests

final class ConversationOptionsViewControllerTests: XCTestCase {
    // MARK: - Properties

    private var mockConversation: MockConversation!
    private var mockUserSession: UserSessionMock!
    private var mockCreateSecuredGuestLinkUseCase: MockCreateConversationGuestLinkUseCaseProtocol!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp method

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        mockConversation = MockConversation()
        mockUserSession = UserSessionMock()
        mockCreateSecuredGuestLinkUseCase = MockCreateConversationGuestLinkUseCaseProtocol()
    }

    // MARK: - tearDown method

    override func tearDown() {
        snapshotHelper = nil
        mockConversation = nil
        mockUserSession = nil
        mockCreateSecuredGuestLinkUseCase = nil

        super.tearDown()
    }

    // MARK: - Helper methods

    private func makeViewModel(config: MockOptionsViewModelConfiguration) -> ConversationGuestOptionsViewModel {
        ConversationGuestOptionsViewModel(
            configuration: config,
            conversation: mockConversation.convertToRegularConversation(),
            createSecureGuestLinkUseCase: mockCreateSecuredGuestLinkUseCase
        )
    }

    // MARK: Renders Guests Screen when AllowGuests is either enabled or disabled

    func testThatItRendersGuestsScreenWhenAllowGuestsIsEnabled() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = makeViewModel(config: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsEnabled_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsDisabled() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)

        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsDisabled_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    // MARK: Renders Guests Screen when Guests link is enabled/disabled etc

    func testThatItRendersAllowGuests_WithLink() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success((
            uri: "https://app.wire.com/772bfh1bbcssjs9826373nbbdsn9917nbbdaehkej827648-72bns9",
            secured: false
        ))
        let viewModel = makeViewModel(config: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success((
            uri: "https://app.wire.com/772bfh1bbcssjs9826373nbbdsn9917nbbdaehkej827648-72bns9",
            secured: false
        ))
        let viewModel = makeViewModel(config: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_Copying() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)

        config.linkResult = .success((
            uri: "https://app.wire.com/772bfh1bbcssjs9826373nbbdsn9917nbbdaehkej827648-72bns9",
            secured: false
        ))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        viewModel.copyInProgress = true
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_DarkTheme_Copying() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success((
            uri: "https://app.wire.com/772bfh1bbcssjs9826373nbbdsn9917nbbdaehkej827648-72bns9",
            secured: false
        ))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        viewModel.copyInProgress = true

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithoutLink() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithoutLink_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsSelfTeamConversation() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = true

        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsSelfTeamConversation_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = true
        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsOtherTeamConversation() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = false
        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsOtherTeamConversation_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = false
        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreEnabled_IsOtherTeamConversation() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .enabled)
        config.isConversationFromSelfTeam = false

        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreEnabled_IsOtherTeamConversation_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .enabled)
        config.isConversationFromSelfTeam = false

        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestLinkFeatureStatusIsUnknown() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .unknown)

        let viewModel = makeViewModel(config: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestLinkFeatureStatusIsUnknown_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .unknown)
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    // MARK: Renders Group's Title in Guests Screen

    func testThatItRendersItsTitle() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = makeViewModel(config: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        // THEN
        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }

    // MARK: Renders Guests Screen when a change is occured

    func testThatItUpdatesWhenItReceivesAChange() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        config.linkResult = .success((uri: nil, secured: false))
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        XCTAssertNotNil(config.allowGuestsChangedHandler)
        config.allowGuests = true
        config.allowGuestsChangedHandler?(true)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItUpdatesWhenItReceivesAChange_Loading() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = makeViewModel(config: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        XCTAssertNotNil(config.allowGuestsChangedHandler)
        config.allowGuests = true
        config.allowGuestsChangedHandler?(true)
        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersLoading() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = makeViewModel(config: config)

        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        let navigationController = sut.wrapInNavigationController()

        // When
        viewModel.setAllowGuests(true, view: .init())

        // Then
        snapshotHelper.verify(matching: navigationController)
    }

    func testThatItRendersLoading_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = makeViewModel(config: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel)
        let navigationController = sut.wrapInNavigationController()
        // WHEN
        viewModel.setAllowGuests(true, view: .init())

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: navigationController)
    }

    // MARK: Renders different kind of alerts

    func testThatItRendersRemoveGuestsConfirmationAlert() throws {
        // WHEN & THEN
        let sut = UIAlertController.confirmRemovingGuests { _ in }
        try verify(matching: sut)
    }

    func testThatItRendersRevokeLinkConfirmationAlert() throws {
        // WHEN & THEN
        let sut = UIAlertController.confirmRevokingLink { _ in }
        try verify(matching: sut)
    }

    func testThatNoAlertIsShowIfNoGuestIsPresent() throws {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.areGuestPresent = false
        let viewModel = makeViewModel(config: config)
        // Show the alert
        let sut = viewModel.setAllowGuests(false, view: .init())
        // THEN
        XCTAssertNil(sut)
    }

    func testThatItRendersRemoveGuestsWarning() throws {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = makeViewModel(config: config)
        // for ConversationOptionsViewModel's delegate
        _ = ConversationGuestOptionsViewController(viewModel: viewModel)
        // Show the alert
        guard let sut = viewModel.setAllowGuests(false, view: .init()) else {
            return XCTFail("This sut shouldn't be nil")
        }
        // THEN
        try verify(matching: sut)
    }

    // MARK: - Unit Tests

    func testThatGuestLinkWithOptionalPasswordAlertShowIfApiVersionIsFourAndAbove() {
        // GIVEN
        BackendInfo.apiVersion = .v4
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = makeViewModel(config: config)
        let mock = MockConversationGuestOptionsViewModelDelegate()
        mock.conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_MockMethod = { _, _, _ in }
        mock.conversationGuestOptionsViewModelDidUpdateState_MockMethod = { _, _ in }
        mock.conversationGuestOptionsViewModelDidReceiveError_MockMethod = { _, _ in }
        viewModel.delegate = mock

        mockCreateSecuredGuestLinkUseCase.invokeConversationPasswordCompletion_MockMethod = { _, _, _ in }

        // WHEN
        viewModel.startGuestLinkCreationFlow(from: .init())

        // THEN
        XCTAssertEqual(
            mock.conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_Invocations.count,
            1
        )
    }

    func testThatGuestLinkWithOptionalPasswordAlertIsNotShownIfApiVersionIsBelowFour() {
        // GIVEN
        BackendInfo.apiVersion = .v3
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = makeViewModel(config: config)

        let mock = MockConversationGuestOptionsViewModelDelegate()
        mock.conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_MockMethod = { _, _, _ in }

        mockCreateSecuredGuestLinkUseCase.invokeConversationPasswordCompletion_MockMethod = { _, _, _ in }

        mock.conversationGuestOptionsViewModelDidUpdateState_MockMethod = { _, _ in }
        mock.conversationGuestOptionsViewModelDidReceiveError_MockMethod = { _, _ in }
        viewModel.delegate = mock

        // WHEN
        viewModel.startGuestLinkCreationFlow(from: .init())

        // THEN
        XCTAssertEqual(
            mock.conversationGuestOptionsViewModelSourceViewPresentGuestLinkTypeSelection_Invocations.count,
            0
        )
    }
}
