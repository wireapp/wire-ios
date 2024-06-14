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

import SwiftUI

/// Displays the image of a user account plus optional availability.
public final class AccountImageView: UIView {

    // MARK: - Constants

    let imageHeight: CGFloat = 27
    let teamAccountImageCornerRadius: CGFloat = 6

    // MARK: - Public Properties

    public var accountImage = UIImage() {
        didSet { updateAccountImage() }
    }

    public var accountType = AccountType.user {
        didSet { updateClippingShape() }
    }

    public var availability: Availability? {
        didSet { updateAvailabilityIndicator() }
    }

    // MARK: - Private Properties

    private let imageView = UIImageView()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Methods

    private func setupSubviews() {

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: imageHeight),
            imageView.heightAnchor.constraint(equalToConstant: imageHeight),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateAccountImage()
        updateClippingShape()
        updateAvailabilityIndicator()
    }

    private func updateAccountImage() {
        imageView.image = accountImage
    }

    private func updateClippingShape() {
        switch accountType {
        case .user:
            imageView.layer.cornerRadius = imageHeight / 2
        case .team:
            imageView.layer.cornerRadius = teamAccountImageCornerRadius
        }
    }

    private func updateAvailabilityIndicator() {
        //
    }

    // MARK: - Nested Types

    public enum AccountType: CaseIterable {
        /// The account image will be clipped using a circle shape.
        case user
        /// The account image will be clipped using a round rectangle shape.
        case team
    }

    public enum Availability: CaseIterable {
        case available, busy, away
    }
}

// MARK: - Previews

struct AccountImageView_Previews: PreviewProvider {

    typealias AccountType = AccountImageView.AccountType
    typealias Availability = AccountImageView.Availability

    static var previews: some View {
        Group {
            ForEach(AccountType.allCases, id: \.self) { accountType in
                let accountImage = switch accountType {
                case .user: userAccountImage
                case .team: teamAccountImage
                }

                AccountImageViewRepresentable(accountImage, accountType)
                    .previewDisplayName("\(accountType)")
                ForEach(Availability.allCases, id: \.self) { availability in
                    AccountImageViewRepresentable(accountImage, accountType)
                        .previewDisplayName("\(accountType) - \(availability)")
                }
            }
        }
        .background(.gray)
    }

    static let userAccountImage = {
        let url = URL(string: "https://wire.com/hs-fs/hubfs/Keyvisual_Homepage_medium.jpg?height=135")!
        let data = try! Data(contentsOf: url)
        return UIImage(data: data)!
    }()

    static let teamAccountImage = {
        let url = URL(string: "https://wire.com/hs-fs/hubfs/WIRE_Logo_rgb_black.png?width=135")!
        let data = try! Data(contentsOf: url)
        return UIImage(data: data)!
    }()
}

private struct AccountImageViewRepresentable: UIViewRepresentable {

    @State var accountImage: UIImage
    @State var accountType: AccountImageView.AccountType

    init(_ accountImage: UIImage, _ accountType: AccountImageView.AccountType) {
        self.accountImage = accountImage
        self.accountType = accountType
    }

    func makeUIView(context: Context) -> AccountImageView {
        let view = AccountImageView()
        view.accountImage = accountImage
        view.accountType = accountType
        return view
    }

    func updateUIView(_ view: AccountImageView, context: Context) {
        view.accountImage = accountImage
        view.accountType = accountType
    }
}
