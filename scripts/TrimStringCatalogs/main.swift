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

import Foundation

// This script removes all languages from a string catalog which are not whitelisted.

guard CommandLine.arguments.count > 1 else {
    print("Usage: \(CommandLine.arguments[0]) [file ...]")
    exit(1)
}

try TrimStringCatalogs(paths: CommandLine.arguments[1...])

func TrimStringCatalogs(paths: some Collection<String>) throws {
    let whitelistedLocalizationKeys = [
        "Base",
        "ar",
        "da",
        "de",
        "en",
        "es",
        "et",
        "fi",
        "fr",
        "it",
        "ja",
        "lt",
        "nl",
        "pl",
        "pt-BR",
        "ru",
        "sl",
        "tr",
        "uk",
        "zh-Hans",
        "zh-Hant",
    ]

    for path in paths {
        let url = URL(fileURLWithPath: path)
        var data = try Data(contentsOf: url)
        print("Trimming \(path) ...")

        // {
        //  "version" : "1.0",
        //  "sourceLanguage" : "en",
        //  "strings" : {
        //    "tabBar.archived.description" : {
        //      "localizations" : {
        //        "ar" : {
        //          "stringUnit" : {
        //            "state" : "translated",
        //            "value" : "حفظ في الأرشيف"
        //          },
        //          ...

        var json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        var strings = json["strings"] as! [String: Any]
        for stringKey in strings.keys {
            var string = strings[stringKey] as! [String: Any]
            var localizations = string["localizations"] as! [String: Any]
            for localizationKey in localizations.keys where !whitelistedLocalizationKeys.contains(localizationKey) {
                localizations.removeValue(forKey: localizationKey)
            }
            string["localizations"] = localizations
            strings[stringKey] = string
        }
        json["strings"] = strings
        data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        data.append(.init("\n".utf8))
        try data.write(to: url)
    }
}
