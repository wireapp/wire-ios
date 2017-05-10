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


#import "ZMServerTrust.h"
@import WireSystem;
#import <mach-o/dyld.h>

static BOOL verifyServerTrustWithPinnedKeys(SecTrustRef const serverTrust, NSArray *pinnedKeys);

// To dump certificate data, use
//     CFIndex const certCount = SecTrustGetCertificateCount(serverTrust);
// and
//     SecCertificateRef cert0 = SecTrustGetCertificateAtIndex(serverTrust, 0);
//     SecCertificateRef cert1 = SecTrustGetCertificateAtIndex(serverTrust, 1);
// etc. and then
//     SecCertificateCopyData(cert1)
// to dump the certificate data.
//
//
// Also
//     CFBridgingRelease(SecCertificateCopyValues(cert1, @[kSecOIDX509V1SubjectName], NULL))

static SecKeyRef publicKeyFromKeyData(NSData *keyData)
{
    NSDictionary *attributes = @{
                                 (NSString *)kSecAttrKeyType: (NSString *)kSecAttrKeyTypeRSA,
                                 (NSString *)kSecAttrKeyClass: (NSString *)kSecAttrKeyClassPublic,
                                 (NSString *)kSecAttrKeySizeInBits: @(keyData.length * 8)
                                 };
    
    CFErrorRef error = nil;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)keyData, (__bridge CFDictionaryRef)attributes, &error);
    
    if (error != nil) {
        [NSException raise:NSInvalidArgumentException format:@"Error while creating pinned key: %@", error, nil];
    }
    
    return key;
}

static SecKeyRef wirePublicKey()
{
    NSString *base64Key = @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAreYzBWuvnVKYfgNNX3dV \
                            jUnqIVtl4XqQnCcY6m/sWM15TTK0bo9FKnMxNAPtDzB6ViRvpZsKEefX8pi15Jcs \
                            4uZiuZ81ISV1bqxtpsjJ56Yjeme99Dca5ck35pThYuK6jZ8vG6pJiY9mRY9nGadi \
                            d4qWL7uwAeoInx2mOM7HepCCh2NOXd+EjQ4sBsfgb+kWrcVQmBzvLHPUDoykm/m+ \
                            BvL2eJ1njPNiM/GoeXbmIW1WM3ifucYJoD9g+V5NfHfANrVu2w4YcLDad0C85Nb8 \
                            U1sgFNkrgOqzhd/1xHok1uOyjoeLTIHHYkryvbBEmdl6v+f2J1EM0+Fj9vseI2TY \
                            rQIDAQAB";
    
    NSData *keyData = [[NSData alloc] initWithBase64EncodedString:base64Key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    SecKeyRef key = publicKeyFromKeyData(keyData);
    
    assert(key != nil);
    
    return key;
}

BOOL verifyServerTrust(SecTrustRef const serverTrust, NSString *host)
{
    NSArray *pinnedKeys = @[];
    
    if (   [host hasSuffix:@"prod-nginz-https.wire.com"]
        || [host hasSuffix:@"prod-nginz-ssl.wire.com"]
        || [host hasSuffix:@"prod-assets.wire.com"]
        || [host hasSuffix:@"www.wire.com"]
        || [host isEqualToString:@"wire.com"]) {
        pinnedKeys = @[CFBridgingRelease(wirePublicKey())];
    }
    
    return verifyServerTrustWithPinnedKeys(serverTrust, pinnedKeys);
}

/// Returns the public key of the leaf certificate associated with the trust object
static SecKeyRef publicKeyAssociatedWithServerTrust(SecTrustRef const serverTrust)
{
    SecKeyRef key = nil;
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0); // leaf certificate
    
    SecCertificateRef certificatesCArray[] = { certificate};
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)certificatesCArray, 1, NULL);
    SecTrustRef trust = NULL;
    
    void(^finally)() = ^{
        if (certificates) {
            CFRelease(certificates);
        }
        
        if (trust) {
            CFRelease(trust);
        }
        
        CFRelease(policy);
    };
    
    if (SecTrustCreateWithCertificates(certificates, policy, &trust) != noErr) {
        finally();
        return nil;
    }
    
    SecTrustResultType result;
    if (SecTrustEvaluate(trust, &result) != noErr) {
        finally();
        return nil;
    }
    
    key = SecTrustCopyPublicKey(trust);
        
    finally();
    
    return key;
}

static BOOL verifyServerTrustWithPinnedKeys(SecTrustRef const serverTrust, NSArray *pinnedKeys)
{
    SecTrustResultType result;
    if (SecTrustEvaluate(serverTrust, &result) != noErr) {
        return NO;
    }
    
    if (result != kSecTrustResultProceed && result != kSecTrustResultUnspecified) {
        return NO;
    }
    
    if (pinnedKeys.count == 0) {
        return YES;
    }
    
    SecKeyRef publicKey = publicKeyAssociatedWithServerTrust(serverTrust);
    
    if (publicKey == nil) {
        return NO;
    }
    
    for (id pinnedKey in pinnedKeys) {
        if ([(__bridge id)publicKey isEqual:pinnedKey]) {
            CFRelease(publicKey);
            return YES;
        }
    }
    
    CFRelease(publicKey);
    return NO;
}
