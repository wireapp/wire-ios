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
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

class ConversationChannelCreationFormTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        UserDefaults.standard.set(true, forKey: "channelsHistory")
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        UserDefaults.standard.set(false, forKey: "channelsHistory")
        snapshotHelper = nil
    }

    @MainActor
    func testColorSchemeVariantsEmptyState() {
        let view = ConversationChannelCreationForm(
            viewModel: ConversationChannelCreationFormViewModel(
                channelName: "",
                isUserPremium: true,
                isWireDriveEnabled: true,
                teamsURL: URL(string: "https://wire.com")!
            ) { _ in }
        )
        .frame(width: 375, height: 667)
        .padding()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariantsEmptyState() {
        let view = ConversationChannelCreationForm(
            viewModel: ConversationChannelCreationFormViewModel(
                channelName: "",
                isUserPremium: true,
                isWireDriveEnabled: true,
                teamsURL: URL(string: "https://wire.com")!
            ) { _ in }
        )
        .frame(width: 375, height: 667)
        .padding()

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    @MainActor
    func testColorSchemeVariantsEmptyState_Visible_Picker() {
        let viewModel = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }

        viewModel.channelHistoryOption = .custom

        let view = ConversationChannelCreationForm(
            viewModel: viewModel
        )
        .frame(width: 375, height: 667)
        .padding()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariantsEmptyState_Visible_Picker() {
        let viewModel = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }

        viewModel.channelHistoryOption = .custom
        let view = ConversationChannelCreationForm(
            viewModel: viewModel
        )
        .frame(width: 375, height: 667)
        .padding()

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    @MainActor
    func testDynamicTypeVariants_Upgrade_Banner_Visible() {
        let viewModel = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }

        viewModel.channelHistoryOption = .custom
        viewModel.showUpgradeBanner = true

        let view = ConversationChannelCreationForm(
            viewModel: viewModel
        )
        .frame(width: 375, height: 667)
        .padding()

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    @MainActor
    func testColorSchemeVariants_Upgrade_Banner_Visible() {
        let viewModel = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }

        viewModel.channelHistoryOption = .custom
        viewModel.showUpgradeBanner = true

        let view = ConversationChannelCreationForm(
            viewModel: viewModel
        )
        .frame(width: 375, height: 667)
        .padding()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

}
