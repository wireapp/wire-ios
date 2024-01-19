//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSyncEngine
import WireCommonComponents

final class AccentColorPickerController: ColorPickerController {
    private let allAccentColors: [AccentColor]

    init() {
        allAccentColors = AccentColor.allSelectable()

        super.init(colors: allAccentColors)

        setupControllerTitle()

        if let selfUser = ZMUser.selfUser(), let accentColor = AccentColor(ZMAccentColor: selfUser.accentColorValue), let currentColorIndex = allAccentColors.firstIndex(of: accentColor) {
            selectedColor = colors[currentColorIndex]
        }
        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isScrollEnabled = false
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupControllerTitle() {
        navigationItem.setupNavigationBarTitle(title: L10n.Localizable.Self.Settings.AccountPictureGroup.color.capitalized)
    }
}

extension AccentColorPickerController: ColorPickerControllerDelegate {

    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: AccentColor) {
        guard let colorIndex = colors.firstIndex(of: color) else {
            return
        }

        ZMUserSession.shared()?.perform {
            ZMUser.selfUser()?.accentColorValue = self.allAccentColors[colorIndex].zmAccentColor
        }
    }

    func colorPickerWantsToDismiss(_ colotPicker: ColorPickerController) {
        dismiss(animated: true, completion: .none)
    }
}
