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

extension URL {

    @discardableResult
    func open() -> Bool {
        let opened = openAsLink()
        if opened {
            return true
        } else {
            log.debug("Did not open \"\(self)\" in a twitter application or third party browser.")
            guard UIApplication.shared.canOpenURL(self) else { return false }
            UIApplication.shared.open(self)
            return true
        }
    }

    private func openInApp(above viewController: UIViewController) {
        let browser = BrowserViewController(url: self)
        browser.modalPresentationCapturesStatusBarAppearance = true
        viewController.present(browser, animated: true, completion: nil)
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
        from presenter: UIViewController?,
        onDismiss: (() -> Void)? = nil
    ) {
        if let browserVC = browserControllerOrOpenExternally() as? BrowserViewController {
            browserVC.onDismiss = onDismiss
            browserVC.modalPresentationCapturesStatusBarAppearance = true
            presenter?.present(browserVC, animated: true)
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

extension UIApplication {

    func canHandleScheme(_ scheme: String) -> Bool {
        URL(string: scheme).map(canOpenURL) ?? false
    }

}
