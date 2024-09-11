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

import WireUserProfile

final class MockGetAccountImageUseCase: GetAccountImageUseCaseProtocol {

    var invoke_Invocations = [(user: any GetAccountImageUseCaseUserProtocol, account: any GetAccountImageUseCaseAccountProtocol)]()
    var invoke_MockValue: UIImage!

    init() {}

    func invoke<User, Account>(user: User, account: Account) async -> UIImage
    where User : GetAccountImageUseCaseUserProtocol, Account : GetAccountImageUseCaseAccountProtocol {
        invoke_Invocations += [(user, account)]
        return invoke_MockValue
    }
}
