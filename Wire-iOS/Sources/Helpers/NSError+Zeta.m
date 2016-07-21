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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 



#import "NSError+Zeta.h"

#import "Guidance.h"


NSString *const ZetaErrorDomain = @"ZMManagedObjectValidation";
NSString *const ZetaValidationGuidanceKey = @"Guidance";


@implementation NSError (Zeta)

+ (instancetype)zetaErrorWithCode:(NSInteger)code userInfo:(NSDictionary *)dict
{
    return [self errorWithDomain:ZetaErrorDomain code:code userInfo:dict];
}

+ (instancetype)zetaValidationErrorWithGuidance:(Guidance *)guidance
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : guidance.description, ZetaValidationGuidanceKey : guidance};
    return [self errorWithDomain:ZetaErrorDomain code:ZetaValidationError userInfo:userInfo];
}

+ (instancetype)zetaErrorWithLocalizedDescription:(NSString *)description
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description};

    return [self zetaErrorWithCode:ZetaUnspecifiedError userInfo:userInfo];
}

- (Guidance *)guidance
{
    return self.userInfo[ZetaValidationGuidanceKey];
}

@end
