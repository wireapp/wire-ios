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

import Foundation
import WireCallingDomain
import WireReusableUIComponents

/// Mock implementation of PasswordValidator for testing and previews
package final class MockPasswordValidator: PasswordValidator {

    var isPasswordValid_MockValue: Bool
    var isPasswordValid_Invocations: [String] = []

    init(isPasswordValid: Bool = true) {
        self.isPasswordValid_MockValue = isPasswordValid
    }

    func isPasswordValid(_ password: String) -> Bool {
        isPasswordValid_Invocations.append(password)
        return isPasswordValid_MockValue
    }

    var localizedRulesDescription: String? {
        "Password must be at least 8 characters"
    }
}
