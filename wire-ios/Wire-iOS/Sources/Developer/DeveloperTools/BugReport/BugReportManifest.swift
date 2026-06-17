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

import UIKit
import WireAnalytics
import WireCommonComponents

/// Structured bug report, serialized as `manifest.json` inside `bug-report-package.zip`.
///
/// Mirrors the schema defined in `HACKATHON_PLAN.md`. The `metadata` block is auto-harvested
/// from the device/session; the `report` block is filled from the guided form.
struct BugReportManifest: Codable, Sendable {

    let schemaVersion: String
    let metadata: Metadata
    let report: Report
    let attachments: [String]

    struct Metadata: Codable, Sendable {
        let timestamp: String
        let appFlavor: String
        let appVersion: String
        let buildNumber: String
        let deviceModel: String
        let osVersion: String
        let locale: String
        let environment: String
        let connectionType: String
        let datadogId: String?
    }

    struct Report: Codable, Sendable {
        let summary: String
        let expectedBehavior: String?
        let actualBehavior: String?
        let timeframe: String
        let stepsToReproduce: [String]
        let reproducibility: String
        let knownWorkaround: String
        let impact: String
        let severity: String
        let regression: String
        let lastKnownWorkingVersion: String?
        let relatedReports: String?
        let additionalNotes: String?
    }
}

extension BugReportManifest.Metadata {

    /// Gathers the technical context that does not require user input.
    ///
    /// `environment` (backend) and `connectionType` are placeholders for the POC and would be
    /// wired to the backend environment provider and reachability before production.
    static func harvested(selfUserID: UUID?) -> Self {
        Self(
            timestamp: BugReportDateFormatter.iso8601.string(from: Date()),
            appFlavor: Bundle.main.appInternalName ?? "development",
            appVersion: Bundle.main.appInfo.version,
            buildNumber: Bundle.main.appInfo.build,
            deviceModel: deviceModelIdentifier(),
            osVersion: UIDevice.current.systemVersion,
            locale: Locale.current.identifier,
            environment: "unknown",
            connectionType: "unknown",
            datadogId: WireAnalytics.Datadog.userIdentifier
        )
    }

    /// Hardware model identifier (e.g. `iPhone15,2`), falling back to the marketing model name.
    private static func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result += String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}

/// Shared ISO-8601 formatter for manifest timestamps.
enum BugReportDateFormatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
