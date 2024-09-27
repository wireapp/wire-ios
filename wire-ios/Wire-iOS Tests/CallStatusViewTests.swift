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

struct MockStatusViewConfiguration: CallStatusViewInputType {
    var state: CallStatusViewState
    var isVideoCall: Bool
    var isConstantBitRate: Bool
    let title: String
    let userEnabledCBR: Bool
    let isForcedCBR: Bool
    var classification: SecurityClassification?
}

final class CallStatusViewTests: XCTestCase {
    private var sut: CallStatusView!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = CallStatusView(
            configuration: MockStatusViewConfiguration(
                state: .connecting,
                isVideoCall: false,
                isConstantBitRate: false,
                title: "Italy Trip",
                userEnabledCBR: false,
                isForcedCBR: false,
                classification: .none
            )
        )
        sut.backgroundColor = .white
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 320).isActive = true
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    func testLongTitleMargins() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .connecting,
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Amazing Way Too Long Group Conversation Name",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testConnectingAudioCallLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .connecting,
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testConnectingAudioCallDark() {
        // WHEN
        sut.backgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(
            state: .connecting,
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testIncomingAudioLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .ringingIncoming(name: "Ulrike"),
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testIncomingAudioLightOneOnOne() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .ringingIncoming(name: nil),
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Miguel",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testIncomingAudioDark() {
        // WHEN
        sut.backgroundColor = SemanticColors.View.backgroundDefault

        sut.configuration = MockStatusViewConfiguration(
            state: .ringingIncoming(name: "Ulrike"),
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testIncomingVideoLight() {
        // WHEN
        sut.backgroundColor = SemanticColors.View.backgroundDefault
        sut.configuration = MockStatusViewConfiguration(
            state: .ringingIncoming(name: "Ulrike"),
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testIncomingVideoDark() {
        // WHEN
        sut.overrideUserInterfaceStyle = .dark
        sut.backgroundColor = SemanticColors.View.backgroundDefault
        sut.configuration = MockStatusViewConfiguration(
            state: .ringingIncoming(name: "Ulrike"),
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testOutgoingLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .ringingOutgoing,
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testOutgoingDark() {
        // WHEN
        sut.backgroundColor = SemanticColors.View.backgroundDefault
        sut.configuration = MockStatusViewConfiguration(
            state: .ringingOutgoing,
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testEstablishedBriefLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 42),
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testEstablishedBriefDark() {
        // WHEN
        sut.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 42),
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testEstablishedLongLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 321),
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testEstablishedLongDark() {
        // WHEN
        sut.backgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 321),
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testConstantBitRateLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 321),
            isVideoCall: false,
            isConstantBitRate: true,
            title: "Italy Trip",
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testConstantBitRateDark() {
        // WHEN
        sut.backgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 321),
            isVideoCall: true,
            isConstantBitRate: true,
            title: "Italy Trip",
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testVariableBitRateLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 321),
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testVariableBitRateDark() {
        // WHEN
        sut.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark
        sut.configuration = MockStatusViewConfiguration(
            state: .established(duration: 321),
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testReconnectingLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .reconnecting,
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testReconnectingDark() {
        // WHEN
        sut.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark
        sut.configuration = MockStatusViewConfiguration(
            state: .reconnecting,
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testEndingLight() {
        // WHEN
        sut.configuration = MockStatusViewConfiguration(
            state: .terminating,
            isVideoCall: false,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testEndingDark() {
        // WHEN
        sut.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark
        sut.configuration = MockStatusViewConfiguration(
            state: .terminating,
            isVideoCall: true,
            isConstantBitRate: false,
            title: "Italy Trip",
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }
}
