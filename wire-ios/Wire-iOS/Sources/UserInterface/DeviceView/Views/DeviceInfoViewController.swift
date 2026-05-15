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

import Combine
import SwiftUI
import WireCommonComponents
import WireDataModel
import WireDesign

/// A customized hosting controller for `DeviceDetailsView` and `OtherUserDeviceDetailsView` in order to allow
/// displaying
/// a custom navigation item title view and a debug menu button in the navigation bar.
final class DeviceInfoViewController<Content>: UIHostingController<Content> where Content: DeviceInfoView {

    private var viewModel: DeviceInfoViewModel { rootView.viewModel }
    private let navigationTitleAdapter = DeviceInfoNavigationTitleAdapter()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItemTitleObservation()
    }

    private func setupNavigationItemTitleObservation() {

        let certificatePublisher = viewModel.$e2eIdentityCertificate
        let isProteusVerifiedPublisher = viewModel.$isProteusVerificationEnabled
        certificatePublisher.combineLatest(isProteusVerifiedPublisher)
            .sink { [weak self] _ in
                self?.updateNavigationItemTitle()
            }
            .store(in: &cancellables)
    }

    private func updateNavigationItemTitle() {

        navigationItem.titleView = navigationTitleAdapter.makeTitleView(
            title: viewModel.title,
            badges: viewModel.navigationTitleBadges
        )
    }
}

private struct DeviceInfoNavigationTitleAdapter {

    func makeTitleView(
        title: String,
        badges: [DeviceInfoViewModel.NavigationTitleBadge]
    ) -> UIView {
        let deviceName = NSMutableAttributedString(string: title)

        badges.compactMap(\.uiImage).forEach { image in
            let attachment = NSTextAttachment(image: image)
            attachment.bounds = .init(origin: .init(x: 0, y: -1.5), size: image.size)
            deviceName.append(.init(string: " "))
            deviceName.append(.init(attachment: attachment))
        }

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = deviceName
        label.font = FontSpec(.header, .semibold).font
        return label
    }
}

private extension DeviceInfoViewModel.NavigationTitleBadge {
    var uiImage: UIImage? {
        switch self {
        case let .e2eIdentity(status):
            status.uiImage
        case .proteusVerified:
            UIImage(resource: .verifiedShield)
        }
    }
}
