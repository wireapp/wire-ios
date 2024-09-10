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

import MapKit
import UIKit
import WireDataModel
import WireDesign

final class ConversationLocationMessageCell: UIView, ConversationMessageCell, ContextMenuDelegate {
    struct Configuration {
        let location: LocationMessageData
        let message: ZMConversationMessage
        var isObfuscated: Bool {
            message.isObfuscated
        }
    }

    private var lastConfiguration: Configuration?

    private var mapView = MKMapView()
    private let containerView = UIView()
    private let obfuscationView = ObfuscationView(icon: .locationPin)
    private let addressContainerView = UIView()
    private let addressLabel = UILabel()
    private var recognizer: UITapGestureRecognizer?
    private weak var locationAnnotation: MKPointAnnotation?

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var labelFont: UIFont? = .normalFont
    var labelTextColor: UIColor? = SemanticColors.Label.textDefault
    var containerColor: UIColor? = SemanticColors.View.backgroundCollectionCell
    var containerHeightConstraint: NSLayoutConstraint!

    var isSelected = false

    var selectionView: UIView? {
        containerView
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = SemanticColors.View.borderCollectionCell.cgColor
        containerView.backgroundColor = SemanticColors.View.backgroundCollectionCell

        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.mapType = .standard
        mapView.pointOfInterestFilter = .includingAll
        mapView.showsBuildings = true
        mapView.isUserInteractionEnabled = false

        recognizer = UITapGestureRecognizer(target: self, action: #selector(openInMaps))
        containerView.addGestureRecognizer(recognizer!)
        addSubview(containerView)
        [mapView, addressContainerView, obfuscationView].forEach(containerView.addSubview)
        addressContainerView.addSubview(addressLabel)
        obfuscationView.isHidden = true

        guard let font = labelFont, let color = labelTextColor, let containerColor else { return }
        addressLabel.font = font
        addressLabel.textColor = color
        addressContainerView.backgroundColor = containerColor
    }

    private func createConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        obfuscationView.translatesAutoresizingMaskIntoConstraints = false
        addressContainerView.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.fitIn(view: self)
        mapView.fitIn(view: containerView)
        obfuscationView.fitIn(view: containerView)

        NSLayoutConstraint.activate([
            // containerView
            containerView.heightAnchor.constraint(equalToConstant: 160),

            // addressContainerView
            addressContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            addressContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            addressContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            addressContainerView.heightAnchor.constraint(equalToConstant: 42),

            // addressLabel
            addressLabel.leadingAnchor.constraint(equalTo: addressContainerView.leadingAnchor, constant: 12),
            addressLabel.topAnchor.constraint(equalTo: addressContainerView.topAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: addressContainerView.trailingAnchor, constant: -12),
            addressLabel.bottomAnchor.constraint(equalTo: addressContainerView.bottomAnchor)
        ])
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            locationAnnotation.map(mapView.removeAnnotation)
        }
    }

    func configure(with object: Configuration, animated: Bool) {
        lastConfiguration = object
        recognizer?.isEnabled = !object.isObfuscated
        obfuscationView.isHidden = !object.isObfuscated
        mapView.isHidden = object.isObfuscated

        if let address = object.location.name {
            addressContainerView.isHidden = false
            addressLabel.text = address
        } else {
            addressContainerView.isHidden = true
        }

        updateMapLocation(withLocationData: object.location)

        if let annotation = locationAnnotation {
            mapView.removeAnnotation(annotation)
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = object.location.coordinate
        mapView.addAnnotation(annotation)
        locationAnnotation = annotation
    }

    func updateMapLocation(withLocationData locationData: LocationMessageData) {
        if locationData.zoomLevel != 0 {
            mapView.setCenterCoordinate(locationData.coordinate, zoomLevel: Int(locationData.zoomLevel))
        } else {
            // As the zoom level is optional we use a viewport of 250m x 250m if none is specified
            let region = MKCoordinateRegion(center: locationData.coordinate, latitudinalMeters: 250, longitudinalMeters: 250)
            mapView.setRegion(region, animated: false)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // The zoomLevel calculation depends on the frame of the mapView, so we need to call this here again
        guard let locationData = lastConfiguration?.location else { return }
        updateMapLocation(withLocationData: locationData)
    }

    @objc
    private func openInMaps() {
        lastConfiguration?.location.openInMaps(with: mapView.region.span)
    }
}

final class ConversationLocationMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLocationMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 0

    let isFullWidth = false
    let supportsActions = true
    let containsHighlightableContent = true

    var accessibilityIdentifier: String? {
        configuration.isObfuscated ? "ObfuscatedLocationCell" : "LocationCell"
    }

    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, location: LocationMessageData) {
        configuration = View.Configuration(location: location, message: message)
    }
}
