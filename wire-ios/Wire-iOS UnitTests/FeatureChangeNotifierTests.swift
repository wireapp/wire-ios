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
import Testing
import UIKit
import WireDomain
import WireDomainSupport

@testable import Wire

@MainActor
@Suite("FeatureChangeNotifier", .serialized)
final class FeatureChangeNotifierTests {

    // MARK: - Fixture

    private let repository = MockFeatureConfigRepositoryProtocol()
    private let featureStates = PassthroughSubject<FeatureState, Never>()
    private let presenter = MockFeatureChangeAlertPresenting()
    private let presented = EventRecorder<UIAlertController>()
    private let handled = EventRecorder<FeatureState>()
    private let acknowledged = EventRecorder<Feature.Name>()
    private var sut: FeatureChangeNotifier?

    init() {
        repository.observeFeatureStates_MockValue = featureStates.eraseToAnyPublisher()
        let acknowledged = acknowledged
        repository.acknowledgeFeatureChangeFor_MockMethod = { name in
            acknowledged.record(name)
        }
        let presented = presented
        presenter.present_MockMethod = { alert in
            presented.record(alert)
        }
    }

    /// A handler that acknowledges the change it is given and returns `alert`.
    private func makeHandler(alert: UIAlertController?) -> MockFeatureChangeHandler {
        let handler = MockFeatureChangeHandler()
        let handled = handled
        handler.alertForAcknowledger_MockMethod = { featureState, acknowledger in
            handled.record(featureState)
            acknowledger.acknowledgeChange(for: featureState.name)
            return alert
        }
        return handler
    }

    /// Creates the notifier and keeps it alive for the duration of the test, since it owns the subscription.
    private func makeSUT(handlers: [Feature.Name: any FeatureChangeHandler] = [:]) {
        let sut = FeatureChangeNotifier(featureConfigRepository: repository, handlers: handlers)
        sut.presenter = presenter
        self.sut = sut
    }

    private func emit(_ name: Feature.Name) {
        featureStates.send(FeatureState(name: name, isEnabled: false, needsToNotifyUser: true))
    }

    private func newAlert() -> UIAlertController {
        UIAlertController(title: "custom", message: nil, preferredStyle: .alert)
    }

    // MARK: - Tests

    @Test("Custom handler is called and its alert is presented")
    func customHandlerAlertIsPresented() async {
        // Given
        let alert = newAlert()
        let handler = makeHandler(alert: alert)
        makeSUT(handlers: [.fileSharing: handler])

        // When
        emit(.fileSharing)

        // Then
        #expect(await presented.next() == alert)
        let receivedStates = handler.alertForAcknowledger_Invocations.map(\.featureState)
        #expect(receivedStates.map(\.name) == [.fileSharing])
        #expect(receivedStates.first?.isEnabled == false)
        #expect(receivedStates.first?.needsToNotifyUser == true)
    }

    @Test("Unregistered feature falls back to default handler and presents an alert")
    func defaultHandlerPresentsAlertForFileSharing() async {
        // Given
        makeSUT()

        // When
        emit(.fileSharing)

        // Then
        await presented.next()
    }

    @Test("Multiple emissions are each handled")
    func multipleEmissions() async {
        // Given
        let fileSharingAlert = newAlert()
        let guestLinksAlert = newAlert()
        makeSUT(handlers: [
            .fileSharing: makeHandler(alert: fileSharingAlert),
            .conversationGuestLinks: makeHandler(alert: guestLinksAlert)
        ])

        // When
        emit(.fileSharing)
        emit(.conversationGuestLinks)

        // Then
        let first = await presented.next()
        let second = await presented.next()
        #expect(Set([first, second]) == Set([fileSharingAlert, guestLinksAlert]))
    }

    @Test("acknowledgeChange forwards to the feature config repository")
    func acknowledgeForwardsToRepository() async {
        // Given
        makeSUT()

        // When
        sut?.acknowledgeChange(for: .fileSharing)

        // Then
        await acknowledged.next()
        #expect(repository.acknowledgeFeatureChangeFor_Invocations == [.fileSharing])
    }

    @Test("Handler acknowledgement reaches the feature config repository")
    func handlerAcknowledgementReachesRepository() async {
        // Given: a handler that acknowledges the change it is given
        let handler = makeHandler(alert: nil)
        makeSUT(handlers: [.fileSharing: handler])

        // When
        emit(.fileSharing)

        // Then
        await acknowledged.next()
        #expect(repository.acknowledgeFeatureChangeFor_Invocations == [.fileSharing])
    }

}

// MARK: - Test doubles

/// Records events and lets a test `await` the next unconsumed one instead of sleeping.
@MainActor
private final class EventRecorder<Event> {
    private(set) var recorded: [Event] = []
    private var unconsumed: [Event] = []
    private var waiters: [CheckedContinuation<Event, Never>] = []

    func record(_ event: Event) {
        recorded.append(event)
        if waiters.isEmpty {
            unconsumed.append(event)
        } else {
            waiters.removeFirst().resume(returning: event)
        }
    }

    @discardableResult
    func next() async -> Event {
        if !unconsumed.isEmpty {
            return unconsumed.removeFirst()
        }
        return await withCheckedContinuation { waiters.append($0) }
    }
}
