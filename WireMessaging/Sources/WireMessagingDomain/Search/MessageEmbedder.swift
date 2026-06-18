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

@preconcurrency import NaturalLanguage

/// Converts text into a semantic vector using the on-device NLEmbedding sentence model.
/// No network calls are made — the model ships with the OS (iOS 14+).
public struct MessageEmbedder: @unchecked Sendable {

    private let embedding: NLEmbedding?

    public init() {
        embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }

    public var isAvailable: Bool { embedding != nil }

    /// Returns a Float32 embedding vector, or `nil` if the on-device model is unavailable.
    public func embed(_ text: String) -> [Float]? {
        guard let vector = embedding?.vector(for: text) else { return nil }
        return vector.map { Float($0) }
    }
}
