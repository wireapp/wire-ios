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

public import WireFoundation

/// If the user went through the flow of registering a new personal account and gave consent to analytics tracking,
/// the newly created analytics id is temporarily stored in this property. After setting up the user session this
/// property will be cleared and the value stored in the database under `ZMUser.trackingID` property.

public enum RegistrationAnalyticsTrackingIDKey: String, DefaultsKey {
    case trackingIDFromRegistration
}
