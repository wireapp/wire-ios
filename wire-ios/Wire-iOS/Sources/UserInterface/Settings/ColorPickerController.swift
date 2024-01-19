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
import WireSyncEngine
import WireCommonComponents

// MARK: - ColorPickerControllerDelegate

protocol ColorPickerControllerDelegate: AnyObject {
    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: AccentColor)
}

class ColorPickerController: UIViewController {

    // MARK: - Properties

    let tableView = UITableView()

    static private let rowHeight: CGFloat = 56

    let colors: [AccentColor]
    var selectedColor: AccentColor?
    weak var delegate: ColorPickerControllerDelegate?

    // MARK: - View lifecycle

    init(colors: [AccentColor]) {
        self.colors = colors
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }

    // MARK: - Setup Views and constraints

    private func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(tableView)

        tableView.register(PickerCell.self, forCellReuseIdentifier: PickerCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        self.navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }

    private func setupConstraints() {
        [tableView].prepareForLayout()

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.heightAnchor.constraint(equalToConstant: Self.rowHeight * CGFloat(colors.count)),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ColorPickerController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return type(of: self).rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PickerCell.reuseIdentifier, for: indexPath) as? PickerCell else {
            fatalError("Cannot create cell")
        }

        let color = colors[indexPath.row]
        cell.color = color
        cell.setColorName(color.name)

        if selectedColor == color {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let color = colors[indexPath.row]
        delegate?.colorPicker(self, didSelectColor: color)
        selectedColor = color
    }

}
