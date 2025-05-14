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
import Combine

public protocol StatusObserverProtocol {
    var statusChangedPublisher: AnyPublisher<MessageModel, Never> { get }
}

public final class MessageStatusViewModel: ObservableObject {
    
    @Published public var deliveryState: MessageToolboxState?
    @Published public var editedString: String?
    @Published var timestamp: String
    
    private var statusObserver: any StatusObserverProtocol

    private var cancellables: Set<AnyCancellable> = []

    public init(
        deliveryState: MessageToolboxState?,
        editedString: String?,
        timestamp: String,
        statusObserver: any StatusObserverProtocol
    ) {
        self.deliveryState = deliveryState
        self.editedString = editedString
        self.timestamp = timestamp
        self.statusObserver = statusObserver
        observeChanges()
    }
    
    func observeChanges() {
        statusObserver.statusChangedPublisher.sink { model in
            let datasource = MessageToolboxDataSource(message: model)
            switch datasource.content {
            case .sendFailure(let string):
                fatalError()
            case .callList(let string):
                fatalError()
            case .details(let timestamp, let status, let countdown):
                self.deliveryState = status
                self.editedString = datasource.editedString
                self.timestamp = timestamp
            }
        }.store(in: &cancellables)
    }
}
