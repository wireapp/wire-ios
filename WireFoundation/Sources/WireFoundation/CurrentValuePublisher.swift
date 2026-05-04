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

public import Combine

/// Helper subject to be able to pass object from which you can get current value and publisher
/// but not able to send values as to regular subject (safety)
public final class CurrentValuePublisher<Output>: Publisher {

    public typealias Failure = Never

    private let subject: CurrentValueSubject<Output, Never>

    public init(subject: CurrentValueSubject<Output, Never>) {
        self.subject = subject
    }

    /// Current value
    public var value: Output {
        subject.value
    }

    /// Read-only publisher
    public var publisher: AnyPublisher<Output, Never> {
        subject.eraseToAnyPublisher()
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }

}
