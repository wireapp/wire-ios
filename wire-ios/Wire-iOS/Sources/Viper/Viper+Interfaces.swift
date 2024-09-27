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

import UIKit

// MARK: - ModuleInterface

/// Represents a single Viper module and is used to construct and connect
/// all the components in the module.

protocol ModuleInterface {
    associatedtype Interactor where Interactor: InteractorInterface
    associatedtype Presenter where Presenter: PresenterInterface
    associatedtype View where View: UIViewController & ViewInterface
    associatedtype Router where Router: RouterInterface

    /// Assembles the module by connecting each component together.

    static func assemble(interactor: Interactor, presenter: Presenter, view: View, router: Router)
}

extension ModuleInterface {
    static func assemble(interactor: Interactor, presenter: Presenter, view: View, router: Router) {
        interactor.presenter = (presenter as! Interactor.PresenterInteractor)
        presenter.interactor = (interactor as! Presenter.InteractorPresenter)
        presenter.router = (router as! Presenter.RouterPresenter)
        presenter.view = (view as! Presenter.ViewPresenter)
        view.presenter = (presenter as! View.PresenterView)
        router.view = (view as! Router.View)
    }
}

// MARK: - InteractorInterface

/// The module component responsible for performing the business logic to fullfill
/// data requests from the presenter.

protocol InteractorInterface: InteractorPresenterInterface {
    associatedtype PresenterInteractor

    /// A weak reference to the presenter.

    var presenter: PresenterInteractor! { get set }
}

// MARK: - PresenterInterface

/// The module component responsible for 1) transforming data from the interactor
/// and presenting it in the view, and 2) responding to ui by engaging with the
/// interactor or router.

protocol PresenterInterface: PresenterInteractorInterface, PresenterViewInterface {
    associatedtype InteractorPresenter
    associatedtype ViewPresenter
    associatedtype RouterPresenter

    /// A strong reference to the interactor.

    var interactor: InteractorPresenter! { get set }

    /// A weak reference to the view.

    var view: ViewPresenter! { get set }

    /// A strong reference to the router.

    var router: RouterPresenter! { get set }
}

// MARK: - ViewInterface

/// The module component responsible for 1) displaying the data received by the
/// presenter, and 2) reporting ui events to the presenter.

protocol ViewInterface: ViewPresenterInterface {
    associatedtype PresenterView

    /// A strong reference to the presenter.

    var presenter: PresenterView! { get set }
}

// MARK: - RouterInterface

/// The module component responsible for navigation to other modules.

protocol RouterInterface: RouterPresenterInterface {
    associatedtype View: UIViewController

    /// A weak reference to the view controller

    var view: View! { get set }
}
