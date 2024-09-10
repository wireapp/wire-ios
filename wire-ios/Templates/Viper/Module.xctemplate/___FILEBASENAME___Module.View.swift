//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit

extension ___VARIABLE_productName:identifier___Module {
    final class View: UIViewController, ViewInterface {
        // MARK: - Properties

        var presenter: ___VARIABLE_productName:identifier___PresenterViewInterface!

        // MARK: - Life cycle

        override func viewDidLoad() {
            super.viewDidLoad()
            presenter.processEvent(.viewDidLoad)
        }
    }
}

// MARK: - View model

extension ___VARIABLE_productName:identifier___Module {
    enum ViewModel: Equatable {}
}

// MARK: - Refresh

extension ___VARIABLE_productName:identifier___Module.View: ___VARIABLE_productName:identifier___ViewPresenterInterface {
    func refresh(withModel model: ___VARIABLE_productName:identifier___Module.ViewModel) {}
}
