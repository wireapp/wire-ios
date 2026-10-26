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

// This is used to erase the type of an `AsyncSequence` to a generic one.
// This is useful because since iOS 18, `AsyncSequence` takes two associated types:
// `Element` and `Failure`.
// This means that if you target iOS 17 and earlier, you can't use `AsyncSequence`,
// as the second argument for `AsyncSequence` is only available in iOS 18 and later.
//
// see https://forums.swift.org/t/possible-to-return-an-asyncsequence-t-for-ios-17-when-building-against-ios-18/76107/2
public struct AnyAsyncSequence<Element, Failure: Error>: AsyncSequence {
    public typealias AsyncIterator = AnyAsyncIterator<Element, Failure>

    private let _makeAsyncIterator: () -> AsyncIterator

    public init<S: AsyncSequence>(_ base: S) where S.Element == Element {
        var baseIterator = base.makeAsyncIterator()
        self._makeAsyncIterator = {
            AnyAsyncIterator {
                try? await baseIterator.next()
            }
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        _makeAsyncIterator()
    }
}

public struct AnyAsyncIterator<Element, Failure: Error>: AsyncIteratorProtocol {
    private let _next: () async throws(Failure) -> Element?

    public init(_ next: @escaping () async -> Element?) {
        self._next = next
    }

    public func next() async throws(Failure) -> Element? {
        try await _next()
    }
}
