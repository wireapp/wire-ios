// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


typedef NS_ENUM(int8_t, ZMBackgroundFetchResult) {
    ZMBackgroundFetchResultFailed = 0,
    ZMBackgroundFetchResultNewData = 1,
    ZMBackgroundFetchResultNoData = 2,
};

typedef void (^ZMBackgroundFetchHandler)(ZMBackgroundFetchResult);


typedef NS_ENUM(int8_t, ZMBackgroundTaskResult) {
    ZMBackgroundTaskResultFailed = 0,
    ZMBackgroundTaskResultSucceed = 1,
    ZMBackgroundTaskResultUnavailable = 2,
};

typedef void (^ZMBackgroundTaskHandler)(ZMBackgroundTaskResult);


