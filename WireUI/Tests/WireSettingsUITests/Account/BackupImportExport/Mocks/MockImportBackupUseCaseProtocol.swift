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

import WireDomainPkg
import Foundation

public final class MockImportBackupUseCaseProtocol: ImportBackupUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeUrlPassword_Invocations: [(url: URL, password: String)] = []
    public var invokeUrlPassword_MockMethod: ((URL, String) -> AsyncThrowingStream<ImportBackupProgress, any Error>)?
    public var invokeUrlPassword_MockValue: AsyncThrowingStream<ImportBackupProgress, any Error>?

    public func invoke(url: URL, password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        invokeUrlPassword_Invocations.append((url: url, password: password))

        if let mock = invokeUrlPassword_MockMethod {
            return mock(url, password)
        } else if let mock = invokeUrlPassword_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUrlPassword`")
        }
    }

}
