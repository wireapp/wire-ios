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

import UniformTypeIdentifiers

// There are some external apps that users can use to transfer backup files, which can modify
// their attachments and change the underscore with a dash. This is the reason we accept two types
// of legacy iOS backup file extensions: 'ios_wbu' and 'ios-wbu'.

public let WireBackupUTIs = [
    UTType("com.wire.backup-universal"),
    UTType("com.wire.backup-ios-underscore"),
    UTType("com.wire.backup-ios-hyphen")
].compactMap(\.self) // in Xcode previews UTType.init returns nil
