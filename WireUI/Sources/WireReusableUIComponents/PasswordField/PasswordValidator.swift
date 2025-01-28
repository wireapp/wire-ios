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

<<<<<<<< HEAD:WireUI/Sources/WireSettingsUI/Account/BackupRestore/Protocols/BackupRestoreAlertPresenterProtocol.swift
public protocol BackupRestoreAlertPresenterProtocol {

    /// <#Description#>
    /// - Returns: <#description#>
    @MainActor
    func todo() async -> Bool
========
public protocol PasswordValidator {

    func validate(_ password: String) -> Bool

    var localizedRulesDescription: String? { get }

>>>>>>>> 019c5676100d5d66e2dc87043a3542a57f403c5e:WireUI/Sources/WireReusableUIComponents/PasswordField/PasswordValidator.swift
}
