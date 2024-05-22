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

import Foundation

/// This is just a placeholder to give the compiler some food.
/// To auto generate mocks via 'sourcery' it uses the plugin configured in `Package.swift`.
/// The generated mocks are processed from the sandbox directory and are not visible in the project folder:
/// https://github.com/apple/swift-package-manager/blob/main/Documentation/Plugins.md#implementing-the-build-tool-plugin-script
enum Mocks { }

extension Mocks {

    /// An Example how generated mocks are structured.
    public class MockExample {

        // MARK: - Life cycle

        public init() {}

        // MARK: lastPrekeyID

        public var lastPrekeyIDCallsCount = 0
        public var lastPrekeyIDCalled: Bool {
            return lastPrekeyIDCallsCount > 0
        }

        public var lastPrekeyID: UInt16 {
            get async {
                lastPrekeyIDCallsCount += 1
                if let lastPrekeyIDClosure {
                    return await lastPrekeyIDClosure()
                } else {
                    return underlyingLastPrekeyID
                }
            }
        }
        public var underlyingLastPrekeyID: UInt16!
        public var lastPrekeyIDClosure: (() async -> UInt16)?

        // MARK: - getName

        public var getNameFor_Invocations: [String] = []
        public var getNameFor_MockError: Error?
        public var getNameFor_MockMethod: ((String) async throws -> String)?
        public var getNameFor_MockValue: String?

        public func getName(for identifier: String) async throws -> String {
            getNameFor_Invocations.append(identifier)

            if let error = getNameFor_MockError {
                throw error
            }

            if let mock = getNameFor_MockMethod {
                return try await mock(identifier)
            } else if let mock = getNameFor_MockValue {
                return mock
            } else {
                fatalError("no mock for `getNameFor`")
            }
        }
    }
}
