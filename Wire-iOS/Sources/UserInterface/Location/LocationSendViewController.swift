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


import Cartography
import Classy

@objc public protocol LocationSendViewControllerDelegate: class {
    func locationSendViewControllerSendButtonTapped(viewController: LocationSendViewController)
}

@objc public final class LocationSendViewController: UIViewController {
    
    public var buttonFont: UIFont? = nil
    public let sendButton = Button(style: .Full)
    public let addressLabel = UILabel()
    public let separatorView = UIView()
    private let containerView = UIView()
    
    weak var delegate: LocationSendViewControllerDelegate?
    
    var address: String? {
        didSet {
            addressLabel.text = address
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        CASStyler.defaultStyler().styleItem(self)
        configureViews()
        createConstraints()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let font = buttonFont else { return }
        sendButton.titleLabel?.font = font
    }
    
    private func configureViews() {
        sendButton.setTitle("location.send_button.title".localized.uppercaseString, forState: .Normal)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), forControlEvents: .TouchUpInside)
        sendButton.accessibilityIdentifier = "sendLocation"
        addressLabel.accessibilityIdentifier = "selectedAddress"
        view.addSubview(containerView)
        [addressLabel, sendButton, separatorView].forEach(containerView.addSubview)
    }

    private func createConstraints() {
        constrain(view, containerView, separatorView, addressLabel, sendButton) { view, container, separator, label, button in
            container.edges == inset(view.edges, 24, 0)
            label.leading == container.leading
            label.trailing <= button.leading - 12 ~ 1000
            label.top == container.top
            label.bottom == container.bottom
            button.trailing == container.trailing
            button.centerY == container.centerY
            button.height == 28
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.top == container.top
            separator.height == 0.5
        }
        
        sendButton.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
        addressLabel.setContentCompressionResistancePriority(750, forAxis: .Horizontal)
    }
    
    @objc private func sendButtonTapped(sender: Button) {
        delegate?.locationSendViewControllerSendButtonTapped(self)
    }
}
