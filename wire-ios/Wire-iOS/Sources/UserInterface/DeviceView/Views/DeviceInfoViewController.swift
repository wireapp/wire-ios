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

import Combine
import WireCommonComponents
import WireDataModel
import SwiftUI

/// A customized hosting controller for `DeviceDetailsView` and `ProfileDeviceDetailsView` in order to allow displaying
/// a custom navigation item title view and a debug menu button in the navigation bar.
final class DeviceInfoViewController<Content>: UIHostingController<Content> where Content: DeviceInfoView {

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItemTitleObservation()
        setupDebugMenuButtonIfNeeded()
    }

    private func setupNavigationItemTitleObservation() {

        let certificatePublisher = rootView.viewModel.$e2eIdentityCertificate
        let isProtuesVerifiedPublisher = rootView.viewModel.$isProteusVerificationEnabled
        certificatePublisher.combineLatest(isProtuesVerifiedPublisher)
            .sink { [weak self] certificate, isProteusVerified in
                self?.updateNavigationItemTitle(certificate, isProteusVerified)
            }
            .store(in: &cancellables)
    }

    private func updateNavigationItemTitle(
        _ certificate: E2eIdentityCertificate?,
        _ isProteusVerified: Bool
    ) {

        let deviceName = NSMutableAttributedString(string: rootView.viewModel.title)
        if
            rootView.viewModel.isE2eIdentityEnabled,
            let certificate,
            let imageForStatus = certificate.status.uiImage {
            let attachment = NSTextAttachment(image: imageForStatus)
            attachment.bounds = .init(origin: .init(x: 0, y: -1.5), size: imageForStatus.size)
            deviceName.append(.init(string: " "))
            deviceName.append(.init(attachment: attachment))
        }
        if isProteusVerified {
            let verifiedShield = UIImage(resource: .verifiedShield)
            let attachment = NSTextAttachment(image: verifiedShield)
            attachment.bounds = .init(origin: .init(x: 0, y: -1.5), size: verifiedShield.size)
            deviceName.append(.init(string: " "))
            deviceName.append(.init(attachment: attachment))
        }

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = deviceName
        label.font = FontSpec(.header, .semibold).font
        navigationItem.titleView = label
    }

    private func setupDebugMenuButtonIfNeeded() {

        if rootView.viewModel.isDebugMenuAvailable {
            let toggleDebugMenu = UIAction(title: "Debug") { [weak self] _ in
                self?.rootView.viewModel.isDebugMenuPresented.toggle()
            }
            let button = UIButton(primaryAction: toggleDebugMenu)
            button.titleLabel?.font = FontSpec(.normal, .regular).font
            navigationItem.rightBarButtonItem = .init(customView: button)
        }
    }
}

// `DeviceDetailsView` and `ProfileDeviceDetailsView` are similar and even use the same view model type.
// The `DeviceInfoView` protocol allows for using the same custom hosting controller for both.
protocol DeviceInfoView: View {
    var viewModel: DeviceInfoViewModel { get }
    init(viewModel: DeviceInfoViewModel)
}
extension DeviceDetailsView: DeviceInfoView {}
extension ProfileDeviceDetailsView: DeviceInfoView {}
