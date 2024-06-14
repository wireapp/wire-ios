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
final class AccountImageView: UIView {

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupSubviews() {
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - Previews

struct AccountImageView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            AccountImageViewRepresentable(value: "Lorem")
                .previewDisplayName("Lorem")
            AccountImageViewRepresentable(value: "Ipsum")
                .previewDisplayName("Ipsum")
        }
    }
}

private struct AccountImageViewRepresentable: UIViewRepresentable {

    @State var value: String

    func makeUIView(context: Context) -> AccountImageView {
        let view = AccountImageView()
        view.label.text = value
        return view
    }

    func updateUIView(_ view: AccountImageView, context: Context) {
        view.label.text = value
    }
}
