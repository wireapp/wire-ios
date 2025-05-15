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

import Combine
import Foundation

public protocol StatusObserverProtocol {
    var statusChangedPublisher: AnyPublisher<MessageModel, Never> { get }
}

public struct StatusDetails {
    let deliveryState: MessageToolboxState?
    let editedString: String?
    let timestamp: String
}

public final class MessageStatusViewModel: ObservableObject {

    public enum State {
        case none
        case sendFailure(String)
        case callList(String)
        case details(StatusDetails)
    }

    @Published var state: State

    private var statusObserver: (any StatusObserverProtocol)?

    private var cancellables: Set<AnyCancellable> = []

    public init(state: State) {
        self.state = state
    }

    public init(
        messageModel: MessageModel,
        statusObserver: any StatusObserverProtocol
    ) {
        self.statusObserver = statusObserver
        self.state = Self.updateState(model: messageModel)
        observeChanges()
    }

    func observeChanges() {
        statusObserver?.statusChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { model in
                print("DS: status ChangedPublisher: \(model)")
                self.state = Self.updateState(model: model)
            }.store(in: &cancellables)
    }

    private static func updateState(model: MessageModel) -> State {
        let datasource = MessageToolboxDataSource(message: model)
        switch datasource.content {
        case let .sendFailure(string):
            return .sendFailure(string)
        case let .callList(string):
            return .callList(string)
        case let .details(timestamp, status, countdown):
            return .details(StatusDetails(
                deliveryState: status,
                editedString: datasource.editedString,
                timestamp: timestamp
            ))
        }
    }
}

public extension MessageStatusViewModel {
    static func none() -> MessageStatusViewModel {
        .init(state: .none)
    }
}
