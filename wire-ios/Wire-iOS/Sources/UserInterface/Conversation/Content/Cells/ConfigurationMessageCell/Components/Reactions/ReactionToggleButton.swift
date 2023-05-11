//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCommonComponents

class ReactionToggleButton: UIControl {

  var isToggled: Bool {
    didSet {
      guard oldValue != isToggled else { return }
      updateAppearance()
    }
  }

  init(isToggled: Bool = false) {
    self.isToggled = isToggled
    super.init(frame: .zero)

    let label = UILabel()
    label.text = "Toggle me!"
    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])

    updateAppearance()
    addTarget(self, action: #selector(didToggle), for: .touchUpInside)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateAppearance() {
    backgroundColor = isToggled ? Sema : .gray
  }

  @objc
  private func didToggle() {
    isToggled.toggle()
  }

}
