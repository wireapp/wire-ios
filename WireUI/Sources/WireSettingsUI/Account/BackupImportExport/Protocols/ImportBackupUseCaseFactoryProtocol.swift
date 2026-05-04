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

public import Foundation
public import WireFoundation

public protocol ImportBackupUseCaseFactoryProtocol {

    /// Returns an implementation of an import backup use case based on the provided file (extension).
    /// - Parameter url: The backup file to import.
    /// - Returns: An implementation which can import the provided file.

    func importBackupUseCase(for url: URL) throws -> any ImportBackupUseCaseProtocol

}
