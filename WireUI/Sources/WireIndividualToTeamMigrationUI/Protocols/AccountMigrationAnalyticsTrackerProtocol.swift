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

public protocol AccountMigrationAnalyticsTrackerProtocol {

    /// Invoked when the user reaches the disclaimer UI.

    func trackMigrationReachedDisclaimerStep()

    /// Invoked when the user reaches the team name selection UI.

    func trackMigrationReachedTeamNameStep()

    /// Invoked when the user reaches the confirmation UI.

    func trackMigrationReachedConfirmationStep()

    /// Invoked when the user cancels on the disclaimer UI.

    func trackMigrationDroppedAtDisclaimerStep()

    /// Invoked when the user cancels on the team name selection UI.

    func trackMigrationDroppedAtTeamNameStep()

    /// Invoked when the user cancels on the confirmation UI.

    func trackMigrationDroppedAtConfirmationStep()

    /// Invoked when the user attempts to cancel the account migration.
    /// - Parameter choice: Specifies if the user confirmed the cancellation or reconsidered.

    func trackMigrationCancelAttempt(choice: CancelAccountMigrationChoice)

    /// Invoked when the user leaves the UI for the account migration.
    /// - Parameter postAction: Specifies which path the user chose to continue after the migration.
    func trackMigrationCompleted(postAction: PostAccountMigrationAction?)

}
