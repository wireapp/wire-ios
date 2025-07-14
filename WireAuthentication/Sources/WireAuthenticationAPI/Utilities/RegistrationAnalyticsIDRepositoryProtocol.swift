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

public import Foundation

// sourcery: AutoMockable
/// A repository which allows reading, writing and deleting a temporary analytics id for the account creation
/// (registration) UI.
public protocol RegistrationAnalyticsIDRepositoryProtocol {

    func storeAnalyticsID(for userID: UUID, analyticsID: UUID) // TODO: Countly uses type String, maybe we shouldn't be more restrictive than needed
    func deleteAnalyticsID(for userID: UUID)
    func updateAnalyticsTrackingConsent(for userID: UUID, isGiven: Bool)

}
