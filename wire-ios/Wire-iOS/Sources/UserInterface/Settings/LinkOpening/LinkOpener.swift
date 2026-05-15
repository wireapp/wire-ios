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

import SafariServices
import UIKit
import WireCommonComponents
import WireSystem

private let log = ZMSLog(tag: "link opening")

protocol LinkOpeningApplication {
    func canOpenURL(_ url: URL) -> Bool
    func openURL(_ url: URL)
    func canHandleScheme(_ scheme: String) -> Bool
}

protocol BrowserOpeningPresenter: AnyObject {
    func presentBrowser(_ viewControllerToPresent: UIViewController, animated: Bool)
}

extension URL {

    @discardableResult
    func open(using application: any LinkOpeningApplication = UIApplication.shared) -> Bool {
        let opened = openAsLink(using: application)
        if opened {
            return true
        } else {
            log.debug("Did not open \"\(self)\" in a twitter application or third party browser.")
            guard application.canOpenURL(self) else { return false }
            application.openURL(self)
            return true
        }
    }

    private func openInApp(above presenter: any BrowserOpeningPresenter) {
        let browser = BrowserViewController(url: self)
        browser.modalPresentationCapturesStatusBarAppearance = true
        presenter.presentBrowser(browser, animated: true)
    }

}

extension URL {

    /// Returns a browser view controller if `openLinksExternally` is false, or opens externally if
    /// `openLinksExternally` is true.
    /// - Returns: A view controller to present, or `nil` if already opened externally.
    func browserControllerOrOpenExternally() -> UIViewController? {
        if SecurityFlags.openLinksExternally.isEnabled {
            open()
            return nil
        } else {
            return BrowserViewController(url: self)
        }
    }

    /// Opens the URL directly: externally if `openLinksExternally` is true, or presents the internal browser from the
    /// given presenter.
    func open(
        from presenter: (any BrowserOpeningPresenter)?,
        onDismiss: (() -> Void)? = nil
    ) {
        if let browserVC = browserControllerOrOpenExternally() as? BrowserViewController {
            browserVC.onDismiss = onDismiss
            browserVC.modalPresentationCapturesStatusBarAppearance = true
            presenter?.presentBrowser(browserVC, animated: true)
        }
    }

}

protocol LinkOpeningOption {
    associatedtype ApplicationOptionEnum: RawRepresentable where ApplicationOptionEnum.RawValue == Int

    static var allOptions: [Self] { get }
    var isAvailable: Bool { get }
    var displayString: String { get }
    static var availableOptions: [Self] { get }

    static var storedPreference: ApplicationOptionEnum { get }
    static var settingKey: SettingKey { get }
    static var defaultPreference: ApplicationOptionEnum { get }
}

extension LinkOpeningOption {

    static var storedPreference: ApplicationOptionEnum {
        if let openingRawValue: ApplicationOptionEnum.RawValue = Settings.shared[settingKey],
           let openingOption = ApplicationOptionEnum(rawValue: openingRawValue) {
            return openingOption
        }

        return defaultPreference
    }

    static var availableOptions: [Self] {
        allOptions.filter(\.isAvailable)
    }

    static var optionsAvailable: Bool {
        availableOptions.count > 1
    }

}

extension UIApplication: LinkOpeningApplication {

    func openURL(_ url: URL) {
        open(url)
    }

    func canHandleScheme(_ scheme: String) -> Bool {
        URL(string: scheme).map(canOpenURL) ?? false
    }

}

extension UIViewController: BrowserOpeningPresenter {

    func presentBrowser(_ viewControllerToPresent: UIViewController, animated: Bool) {
        present(viewControllerToPresent, animated: animated)
    }

}
