//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

<<<<<<<< HEAD:WireAnalytics/Sources/WireAnalytics/Events/Segmentation/AnalyticsEvent.Segmentation+convenienceInit.swift
public import WireFoundation

extension AnalyticsEvent.Segmentation {

    public init(key: String, value: Int) {
        self.init(
            key: key,
            value: "\(value)"
        )
    }

    public init(key: String, value: Int32) {
        self.init(
            key: key,
            value: "\(value)"
        )
    }

    public init(key: String, value: Bool) {
        self.init(
            key: key,
            value: value ? "True" : "False"
        )
    }

========
import WireBackup
import WireProtos

extension MessageBackupModel.Content.AssetContent.EncryptionAlgorithm {

    init(_ encryptionAlgorithm: WireProtos.EncryptionAlgorithm) {
        switch encryptionAlgorithm {
        case .aesCbc:
            self = .aesCBC
        case .aesGcm:
            self = .aesGCM
        }
    }

>>>>>>>> e51ed70bed90c4d1b450f7b84370614c7f0fc57b:wire-ios/Wire-iOS/Sources/UserInterface/Settings/Backup/BackupLocalStore/MessageContent.AssetContent.EncryptionAlgorithm+initWithWireProtos.EncryptionAlgorithm.swift
}
