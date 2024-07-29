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

import Foundation
import WireSystemPackage

struct DidPresentNotificationPermissionHintUseCase<DateProvider>: DidPresentNotificationPermissionHintUseCaseProtocol
where DateProvider: CurrentDateProviding {

    var currentDateProvider: DateProvider
    var userDefaults: UserDefaults

    func invoke() {
        userDefaults.setValue(currentDateProvider.now, for: .lastTimeNotificationPermissionHintWasShown)
    }
}

// MARK: - DidPresentNotificationPermissionHintUseCase + init()

extension DidPresentNotificationPermissionHintUseCase where DateProvider == SystemDateProvider {

    init(
        currentDateProvider: SystemDateProvider = .init(),
        userDefaults: UserDefaults = .standard
    ) {
        self.currentDateProvider = currentDateProvider
        self.userDefaults = userDefaults
    }
}
