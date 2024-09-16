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

public enum MainLayoutStatus {
    /// The main split view controller is collapsed, either due to running on a phone
    /// or running on iPad in split screen mode or with stage manager and having
    /// the window of the app shrunk to horizontal compact size class.
    case collapsed

    /// Running on iPad with split view controller being fully visible.
    case expanded
}
