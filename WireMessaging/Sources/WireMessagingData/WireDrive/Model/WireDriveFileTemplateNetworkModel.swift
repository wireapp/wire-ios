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

import CellsSDK
package import WireMessagingDomain

package struct WireDriveFileTemplateNetworkModel: Equatable, Hashable, Sendable {
    package let templates: [Template]?

    package struct Template: Equatable, Hashable, Sendable {
        let editable: Bool?
        let label: String?
        let UUID: String?
    }

}

package extension WireDriveFileTemplateNetworkModel {
    func toDomainModel() -> [WireDriveFileTemplate]? {
        templates?.compactMap { value -> WireDriveFileTemplate? in
            guard let label = value.label,
                  let UUID = value.UUID else {
                return nil
            }

            // TODO: [WPB-22926] Finish mapping when GET/ templates endpoint ready.
            let kind: WireDriveFileTemplate.Kind = switch label {
            case "Microsoft Word":
                .document
            case "Microsoft Excel":
                .spreadsheet
            case "Microsoft PowerPoint":
                .presentation
            default:
                .document
            }

            return WireDriveFileTemplate(
                kind: kind,
                editable: value.editable,
                label: label,
                id: UUID
            )
        }
    }
}

package extension RestListTemplatesResponse {
    func toDTO() -> WireDriveFileTemplateNetworkModel? {
        templates.map {
            WireDriveFileTemplateNetworkModel(
                templates: $0.map {
                    .init(editable: $0.editable, label: $0.label, UUID: $0.UUID)
                }
            )
        }
    }
}
