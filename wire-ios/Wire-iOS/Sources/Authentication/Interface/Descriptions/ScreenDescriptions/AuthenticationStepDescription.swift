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

typealias AuthenticationSecondaryViewDescription = AuthenticationActionable & SecondaryViewDescription

typealias AuthenticationFooterViewDescription = AuthenticationActionable & FooterViewDescription

typealias ValueSubmitted = (Any) -> Void
typealias ValueValidated = (ValueValidation?) -> Void

// MARK: - ValueValidation

enum ValueValidation {
    case info(String)
    case error(TextFieldValidator.ValidationError, showVisualFeedback: Bool)
}

// MARK: - ViewDescriptor

protocol ViewDescriptor: AnyObject {
    func create() -> UIView
}

// MARK: - ValueSubmission

protocol ValueSubmission: AnyObject {
    var acceptsInput: Bool { get set }
    var valueSubmitted: ValueSubmitted? { get set }
    var valueValidated: ValueValidated? { get set }
}

// MARK: - MagicTappable

/// A protocol for views that support performing the magic tap.
protocol MagicTappable: AnyObject {
    func performMagicTap() -> Bool
}

// MARK: - AuthenticationStepDescription

protocol AuthenticationStepDescription {
    var backButton: BackButtonDescription? { get }
    var mainView: ViewDescriptor & ValueSubmission { get }
    var headline: String { get }
    var subtext: NSAttributedString? { get }
    var secondaryView: AuthenticationSecondaryViewDescription? { get }
    var footerView: AuthenticationFooterViewDescription? { get }
}

// MARK: - DefaultValidatingStepDescription

protocol DefaultValidatingStepDescription: AuthenticationStepDescription {
    var initialValidation: ValueValidation { get }
}
