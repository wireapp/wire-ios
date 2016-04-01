// 
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
// 


@class ZMUpstreamRequest;
@class ZMManagedObject;

@protocol ZMUpstreamTranscoder <NSObject>

- (BOOL)shouldProcessUpdatesBeforeInserts;

- (ZMUpstreamRequest *)requestForUpdatingObject:(ZMManagedObject *)managedObject forKeys:(NSSet *)keys;
- (ZMUpstreamRequest *)requestForInsertingObject:(ZMManagedObject *)managedObject forKeys:(NSSet *)keys;

- (void)updateInsertedObject:(ZMManagedObject *)managedObject request:(ZMUpstreamRequest *)upstreamRequest response:(ZMTransportResponse *)response;

/// Returns whether synchronization of this object needs additional requests
- (BOOL)updateUpdatedObject:(ZMManagedObject *)managedObject
            requestUserInfo:(NSDictionary *)requestUserInfo
                   response:(ZMTransportResponse *)response
                keysToParse:(NSSet *)keysToParse;

// Should return the objects that need to be refetched from the BE in case of upload error
- (ZMManagedObject *)objectToRefetchForFailedUpdateOfObject:(ZMManagedObject *)managedObject;

@optional

/// If implemented, the upstream object sync will call this before inserting any objects into either
/// its inserted or updated objects collection. If the transcoder returns no dependency (e.g. @c nil),
/// the object (@c dependant) will get inserted.
///
/// If a dependency gets returned, the dependant is put on hold until the returned dependency is updated
/// at which time the upstream object sync will ask the transcoder again.
///
/// Dependant -> depends on -> dependency
- (ZMManagedObject *)dependentObjectNeedingUpdateBeforeProcessingObject:(ZMManagedObject *)dependant;

/// If implemented, the upstream object sync will call this when an upstream request timed out. Having a request
/// that might time out but not implementing this will trigger an assertion.
- (void)requestExpiredForObject:(ZMManagedObject *)managedObject forKeys:(NSSet *)keys;

/// If implemented, the transcoder can refuse requests until a conditions is fullfilled
/// Object will be not removed from objects to be synced
- (BOOL)shouldCreateRequestToSyncObject:(ZMManagedObject *)managedObject withSync:(id)sync;

/// If this method is not implemented, inserted sync will delete object. If this method reutrns TRUE than object will be added back to sync queue
- (BOOL)failedToUpdateInsertedObject:(ZMManagedObject *)managedObject
                             request:(ZMUpstreamRequest *)upstreamRequest
                            response:(ZMTransportResponse *)response
                         keysToParse:(NSSet *)keys;

@end

/// Asserts with a description of how it failed to generate a request from a transcoder
void ZMTrapUnableToGenerateRequest(NSSet *keys, id transcoder);
