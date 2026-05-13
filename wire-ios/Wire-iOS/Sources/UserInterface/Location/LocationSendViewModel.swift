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

import Foundation
import WireDataModel

// MARK: - LocationSendViewModel

final class LocationSendViewModel {

    // MARK: - Nested Types

    struct SelectedLocationPayload {
        let latitude: Float
        let longitude: Float
        let address: String?
        let zoomLevel: Int32

        var locationData: LocationData {
            .locationData(
                withLatitude: latitude,
                longitude: longitude,
                name: address,
                zoomLevel: zoomLevel
            )
        }
    }

    struct DisplayState {
        let sendButtonTitle: String
        let sendButtonAccessibilityIdentifier: String
        let selectedAddressAccessibilityIdentifier: String
        let selectedAddressAccessibilityLabel: String
        let selectedAddressAccessibilityHint: String
        let selectedAddress: String?
        let canSend: Bool
        let shouldUseCompactHeight: Bool
        let selectedLocationPayload: SelectedLocationPayload?
    }

    enum Action {
        case updateSelectedAddress(String?)
        case updateSelectedLocation(latitude: Float, longitude: Float, zoomLevel: Int32)
        case sendButtonTapped
    }

    enum Route {
        case send(LocationData)
        case updateHeight(Bool)
    }

    // MARK: - Properties

    private let sendButtonTitle: String
    private let sendButtonAccessibilityIdentifier: String
    private let selectedAddressAccessibilityIdentifier: String
    private let selectedAddressAccessibilityHint: String
    private let selectedAddressAccessibilityLabel: (String?) -> String

    private var selectedAddress: String?
    private var latitude: Float?
    private var longitude: Float?
    private var zoomLevel: Int32?

    // MARK: - Life Cycle

    init(
        sendButtonTitle: String = L10n.Localizable.Location.SendButton.title,
        sendButtonAccessibilityIdentifier: String = "sendLocation",
        selectedAddressAccessibilityIdentifier: String = "selectedAddress",
        selectedAddressAccessibilityHint: String = L10n.Accessibility.SendLocation.Address.hint,
        selectedAddressAccessibilityLabel: @escaping (String?) -> String = {
            L10n.Accessibility.SendLocation.Address.description($0 ?? "")
        }
    ) {
        self.sendButtonTitle = sendButtonTitle
        self.sendButtonAccessibilityIdentifier = sendButtonAccessibilityIdentifier
        self.selectedAddressAccessibilityIdentifier = selectedAddressAccessibilityIdentifier
        self.selectedAddressAccessibilityHint = selectedAddressAccessibilityHint
        self.selectedAddressAccessibilityLabel = selectedAddressAccessibilityLabel
    }

    // MARK: - Accessors

    var displayState: DisplayState {
        let selectedLocationPayload = selectedLocationPayload

        return DisplayState(
            sendButtonTitle: sendButtonTitle,
            sendButtonAccessibilityIdentifier: sendButtonAccessibilityIdentifier,
            selectedAddressAccessibilityIdentifier: selectedAddressAccessibilityIdentifier,
            selectedAddressAccessibilityLabel: selectedAddressAccessibilityLabel(selectedAddress),
            selectedAddressAccessibilityHint: selectedAddressAccessibilityHint,
            selectedAddress: selectedAddress,
            canSend: selectedLocationPayload != nil,
            shouldUseCompactHeight: selectedAddress?.isEmpty ?? true,
            selectedLocationPayload: selectedLocationPayload
        )
    }

    // MARK: - Actions

    @discardableResult
    func perform(_ action: Action) -> [Route] {
        switch action {
        case let .updateSelectedAddress(address):
            selectedAddress = address
            return [.updateHeight(displayState.shouldUseCompactHeight)]

        case let .updateSelectedLocation(latitude, longitude, zoomLevel):
            self.latitude = latitude
            self.longitude = longitude
            self.zoomLevel = zoomLevel
            return []

        case .sendButtonTapped:
            guard let locationData = displayState.selectedLocationPayload?.locationData else { return [] }
            return [.send(locationData)]
        }
    }

    // MARK: - Helpers

    private var selectedLocationPayload: SelectedLocationPayload? {
        guard let latitude, let longitude, let zoomLevel else { return nil }

        return SelectedLocationPayload(
            latitude: latitude,
            longitude: longitude,
            address: selectedAddress,
            zoomLevel: zoomLevel
        )
    }

}
