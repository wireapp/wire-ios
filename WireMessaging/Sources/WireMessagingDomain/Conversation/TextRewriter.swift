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

import FoundationModels

/// Rewrites a chat message draft in a chosen style using the on-device Apple Intelligence model.
/// All processing is on-device — no content leaves the device.
@available(iOS 26.0, *)
public struct TextRewriter {

    public enum Style: CaseIterable {
        case polite
        case concise
        case formal

        public var label: String {
            switch self {
            case .polite: "Make Polite"
            case .concise: "Make Concise"
            case .formal: "Make Formal"
            }
        }

        var instruction: String {
            switch self {
            case .polite:
                "Rewrite this message to sound more polite and friendly, while keeping the same meaning."
            case .concise:
                "Rewrite this message to be shorter and more to the point, keeping all key information."
            case .formal:
                "Rewrite this message in a professional, formal tone suitable for business communication."
            }
        }
    }

    public init() {}

    /// `true` when the on-device Apple Intelligence model is available.
    /// Returns `false` on the simulator or when Apple Intelligence has not been set up.
    public static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// Returns the message rewritten in the given style, or throws on model error.
    public func rewrite(_ text: String, style: Style) async throws -> String {
        let session = LanguageModelSession()
        let prompt = """
        \(style.instruction) Output only the rewritten message — no explanation, no quotes, no preamble.

        Original message:
        \(text)
        """
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
