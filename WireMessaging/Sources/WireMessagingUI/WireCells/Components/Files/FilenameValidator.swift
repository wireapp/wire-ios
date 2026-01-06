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

import Combine

struct FilenameValidator {

    private enum Constants {
        static let maxInputLength = 64
    }

    enum Failure: Error {
        case tooLong
        case dotPrefix
        case slashCharacter
        case empty
    }

    func validate(_ input: String) -> AnyPublisher<Result<Void, Failure>, Never> {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        let result: Result<Void, Failure> = if trimmedInput.isEmpty {
            .failure(.empty)
        } else if input.hasPrefix(".") {
            .failure(.dotPrefix)
        } else if input.count > Constants.maxInputLength {
            .failure(.tooLong)
        } else if input.contains("/") {
            .failure(.slashCharacter)
        } else {
            .success(())
        }

        return Just(result).eraseToAnyPublisher()
    }
}
