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

@MainActor
final class KMPViewModelAdapterTests: XCTestCase {

    func testAdapterPublishesStateAndEffectsAndForwardsIntent() {
        // GIVEN
        let source = makeSource(initialState: .idle)
        let sut = source.makeAdapter()
        let recorder = KMPViewModelAdapterRecorder(adapter: sut)

        // WHEN
        source.publish(state: .loaded("conversation-list"))
        source.publish(effect: .showToast("synced"))
        sut.send(.refresh)

        // THEN
        recorder.assertStates([.idle, .loaded("conversation-list")])
        recorder.assertEffects([.showToast("synced")])
        source.assertSentIntents([.refresh])
        source.assertObserving()
    }

    func testCloseDisconnectsObservationsAndClosesSource() {
        // GIVEN
        let source = makeSource(initialState: .idle)
        let sut = source.makeAdapter()
        let recorder = KMPViewModelAdapterRecorder(adapter: sut)

        // WHEN
        sut.close()
        source.publish(state: .loaded("after-close"))
        source.publish(effect: .showToast("ignored"))
        sut.send(.refresh)
        sut.close()

        // THEN
        recorder.assertStates([.idle])
        recorder.assertEffects([])
        source.assertClosed()
        source.assertSentIntents([])
    }

    func testDeinitAfterCloseDoesNotCloseSourceTwice() {
        // GIVEN
        let source = makeSource(initialState: .idle)
        var sut: KMPViewModelAdapter<TestState, TestEffect, TestIntent>? = source.makeAdapter()

        // WHEN
        sut?.close()
        sut = nil

        // THEN
        source.assertClosed()
    }

    func testDefaultFactoryBuildsAdapterFromDescriptor() {
        // GIVEN
        let source = makeSource(initialState: .idle)
        var makeSourceCallsCount = 0
        let descriptor = KMPViewModelDescriptor<TestState, TestEffect, TestIntent> {
            makeSourceCallsCount += 1
            return source
        }
        let sut = DefaultKMPViewModelFactory()

        // WHEN
        let viewModel = sut.makeViewModel(for: descriptor)
        source.publish(state: .loaded("from-factory"))
        viewModel.send(.refresh)

        // THEN
        XCTAssertEqual(makeSourceCallsCount, 1)
        XCTAssertEqual(viewModel.state, .loaded("from-factory"))
        source.assertSentIntents([.refresh])
    }

    func testHostOwnsAdapterCreatedByFactory() {
        // GIVEN
        let source = makeSource(initialState: .idle)

        // WHEN
        let sut = source.makeHost()
        source.publish(effect: .showToast("hosted"))

        // THEN
        assertTestHost(sut)
        XCTAssertEqual(sut.viewModel.effect, .showToast("hosted"))
    }

    func testHostCanWrapExistingAdapter() {
        // GIVEN
        let source = makeSource(initialState: .idle)
        let viewModel = source.makeAdapter()

        // WHEN
        let sut = KMPViewModelHost(viewModel: viewModel)

        // THEN
        XCTAssertTrue(sut.viewModel === viewModel)
        assertTestHost(sut)
    }

    private func assertTestHost<Host: KMPViewModelHosting>(
        _ host: Host
    ) where Host.State == TestState, Host.Effect == TestEffect, Host.Intent == TestIntent {
        XCTAssertEqual(host.viewModel.state, .idle)
    }

    private func makeSource(
        initialState: TestState
    ) -> FakeKMPViewModelSource<TestState, TestEffect, TestIntent> {
        FakeKMPViewModelSource(initialState: initialState)
    }
}

// MARK: - Test Types

private enum TestState: Equatable {
    case idle
    case loaded(String)
}

private enum TestEffect: Equatable {
    case showToast(String)
}

private enum TestIntent: Equatable {
    case refresh
}
