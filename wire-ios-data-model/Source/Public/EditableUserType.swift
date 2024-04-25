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

import WireUtilities

@objc(ZMEditableUserType)
public protocol EditableUserType: NSObjectProtocol {
    var name: String? { get set }
    var accentColorValue: ZMAccentColorRawValue { get set }
    var emailAddress: String? { get set }
    var phoneNumber: String? { get set }
    var readReceiptsEnabled: Bool { get set }
    var needsRichProfileUpdate: Bool { get set }
}
