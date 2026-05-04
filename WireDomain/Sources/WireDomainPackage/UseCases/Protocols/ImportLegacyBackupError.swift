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

public enum ImportLegacyBackupError: Error, Equatable, CaseIterable {
    case noActiveAccountForImport
    /// The backup file is encrypted and a password is needed for decryption.
    case passwordRequired
    /// E.g. if the file to import was created with a different (incompatible) version of the app.
    case invalidAccountID
    case unarchivingFailed
    case keyCreationFailed
    case decryptionError
    case failedToBackUpUserClient
    /// Failed to create `InputStream` or `OutputStream` from `URL`.
    case failedToCreateStreamForDecryption
}
