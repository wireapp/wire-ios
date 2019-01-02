//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

#import <XCTest/XCTest.h>
#import "ZMServerTrust.h"
#import "WireTransport_ios_tests-Swift.h"

@import WireTesting;
@import WireUtilities;


@interface ZMServerTrustTests : ZMTBaseTest
@end

@implementation ZMServerTrustTests

/*
 The whole certificate chain for production.
 
  ---
 
 To export a certificate in ascii PEM format, run:
 
 openssl s_client -connect wire.com:443 -showcerts
 
 */
- (NSArray *)productionCertificateChain
{
    
    NSString *cert0 = @"\
    MIIE/jCCA+agAwIBAgIQBmeNK7xaqmvwoGsKbGiEuzANBgkqhkiG9w0BAQsFADBN \
    MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5E \
    aWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMTcxMjEyMDAwMDAwWhcN \
    MTkwMjAxMTIwMDAwWjBKMQswCQYDVQQGEwJDSDEMMAoGA1UEBxMDWnVnMRgwFgYD \
    VQQKEw9XaXJlIFN3aXNzIEdtYkgxEzARBgNVBAMMCioud2lyZS5jb20wggEiMA0G \
    CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCt5jMFa6+dUph+A01fd1WNSeohW2Xh \
    epCcJxjqb+xYzXlNMrRuj0UqczE0A+0PMHpWJG+lmwoR59fymLXklyzi5mK5nzUh \
    JXVurG2myMnnpiN6Z730NxrlyTfmlOFi4rqNny8bqkmJj2ZFj2cZp2J3ipYvu7AB \
    6gifHaY4zsd6kIKHY05d34SNDiwGx+Bv6RatxVCYHO8sc9QOjKSb+b4G8vZ4nWeM \
    82Iz8ah5duYhbVYzeJ+5xgmgP2D5Xk18d8A2tW7bDhhwsNp3QLzk1vxTWyAU2SuA \
    6rOF3/XEeiTW47KOh4tMgcdiSvK9sESZ2Xq/5/YnUQzT4WP2+x4jZNitAgMBAAGj \
    ggHbMIIB1zAfBgNVHSMEGDAWgBQPgGEcgjFh1S8o541GOLQs4cbZ4jAdBgNVHQ4E \
    FgQU/0iA8JzB4tDtwNB/3NyYfCtfTZwwHwYDVR0RBBgwFoIKKi53aXJlLmNvbYII \
    d2lyZS5jb20wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr \
    BgEFBQcDAjBrBgNVHR8EZDBiMC+gLaArhilodHRwOi8vY3JsMy5kaWdpY2VydC5j \
    b20vc3NjYS1zaGEyLWc2LmNybDAvoC2gK4YpaHR0cDovL2NybDQuZGlnaWNlcnQu \
    Y29tL3NzY2Etc2hhMi1nNi5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAQEwKjAo \
    BggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwB \
    AgIwfAYIKwYBBQUHAQEEcDBuMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp \
    Y2VydC5jb20wRgYIKwYBBQUHMAKGOmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv \
    bS9EaWdpQ2VydFNIQTJTZWN1cmVTZXJ2ZXJDQS5jcnQwDAYDVR0TAQH/BAIwADAN \
    BgkqhkiG9w0BAQsFAAOCAQEAc6v6cf/EQmmeGU2nC87F6QgEIAIL3svgabImao3f \
    01QFVxC0XX2Cf9+wofijspqq5Uj80nb04o5HNnZWX1agJmqp8jTYH2hw4+uiwFCl \
    d0QEptHMrCwEAyyouf0/cl2dfRv2V8m29W6Qb4+7pc1rEbFLl3fywmjgzpGkr1+c \
    KE7pwkpgKqhulKkE4CDXant0Slj7cvDisSPy/kInJ5uHI29Z/SBCpACyHah6lkdI \
    QyTo4uem1XH6i5UP9sTvCAZl0acHcPsvcJ50LeJvJC7sPNXr60xZYLIK5LIVrSSR \
    hxtOB1WPMbzIQc5bF2LcSjXJNvXA5+RCO79om91mlheqPQ==";
    
    NSString *cert1 = @"\
    MIIElDCCA3ygAwIBAgIQAf2j627KdciIQ4tyS8+8kTANBgkqhkiG9w0BAQsFADBh \
    MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3 \
    d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD \
    QTAeFw0xMzAzMDgxMjAwMDBaFw0yMzAzMDgxMjAwMDBaME0xCzAJBgNVBAYTAlVT \
    MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxJzAlBgNVBAMTHkRpZ2lDZXJ0IFNIQTIg \
    U2VjdXJlIFNlcnZlciBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB \
    ANyuWJBNwcQwFZA1W248ghX1LFy949v/cUP6ZCWA1O4Yok3wZtAKc24RmDYXZK83 \
    nf36QYSvx6+M/hpzTc8zl5CilodTgyu5pnVILR1WN3vaMTIa16yrBvSqXUu3R0bd \
    KpPDkC55gIDvEwRqFDu1m5K+wgdlTvza/P96rtxcflUxDOg5B6TXvi/TC2rSsd9f \
    /ld0Uzs1gN2ujkSYs58O09rg1/RrKatEp0tYhG2SS4HD2nOLEpdIkARFdRrdNzGX \
    kujNVA075ME/OV4uuPNcfhCOhkEAjUVmR7ChZc6gqikJTvOX6+guqw9ypzAO+sf0 \
    /RR3w6RbKFfCs/mC/bdFWJsCAwEAAaOCAVowggFWMBIGA1UdEwEB/wQIMAYBAf8C \
    AQAwDgYDVR0PAQH/BAQDAgGGMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYY \
    aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMHsGA1UdHwR0MHIwN6A1oDOGMWh0dHA6 \
    Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RDQS5jcmwwN6A1 \
    oDOGMWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RD \
    QS5jcmwwPQYDVR0gBDYwNDAyBgRVHSAAMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8v \
    d3d3LmRpZ2ljZXJ0LmNvbS9DUFMwHQYDVR0OBBYEFA+AYRyCMWHVLyjnjUY4tCzh \
    xtniMB8GA1UdIwQYMBaAFAPeUDVW0Uy7ZvCj4hsbw5eyPdFVMA0GCSqGSIb3DQEB \
    CwUAA4IBAQAjPt9L0jFCpbZ+QlwaRMxp0Wi0XUvgBCFsS+JtzLHgl4+mUwnNqipl \
    5TlPHoOlblyYoiQm5vuh7ZPHLgLGTUq/sELfeNqzqPlt/yGFUzZgTHbO7Djc1lGA \
    8MXW5dRNJ2Srm8c+cftIl7gzbckTB+6WohsYFfZcTEDts8Ls/3HB40f/1LkAtDdC \
    2iDJ6m6K7hQGrn2iWZiIqBtvLfTyyRRfJs8sjX7tN8Cp1Tm5gr8ZDOo0rwAhaPit \
    c+LJMto4JQtV05od8GiG7S5BNO98pVAdvzr508EIDObtHopYJeS4d60tbvVS3bR0 \
    j6tJLp07kzQoH3jOlOrHvdPJbRzeXDLz";
    
    NSString *cert2 = @"\
    MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh \
    MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3 \
    d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD \
    QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT \
    MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j \
    b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG \
    9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB \
    CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97 \
    nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt \
    43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P \
    T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4 \
    gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO \
    BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR \
    TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw \
    DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr \
    hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg \
    06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF \
    PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls \
    YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk \
    CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=";
    
    return @[[[NSData alloc] initWithBase64EncodedString:cert0 options:NSDataBase64DecodingIgnoreUnknownCharacters],
             [[NSData alloc] initWithBase64EncodedString:cert1 options:NSDataBase64DecodingIgnoreUnknownCharacters],
             [[NSData alloc] initWithBase64EncodedString:cert2 options:NSDataBase64DecodingIgnoreUnknownCharacters]];
}

- (NSArray *)externalCertificateChain
{
    NSString *cert0 = @"\
    MIIHXDCCBkSgAwIBAgIIU0E9kXjSjCcwDQYJKoZIhvcNAQELBQAwSTELMAkGA1UE \
    BhMCVVMxEzARBgNVBAoTCkdvb2dsZSBJbmMxJTAjBgNVBAMTHEdvb2dsZSBJbnRl \
    cm5ldCBBdXRob3JpdHkgRzIwHhcNMTcwNDI3MDgzMDAwWhcNMTcwNzIwMDgzMDAw \
    WjBmMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTEWMBQGA1UEBwwN \
    TW91bnRhaW4gVmlldzETMBEGA1UECgwKR29vZ2xlIEluYzEVMBMGA1UEAwwMKi5n \
    b29nbGUuY29tMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEvU0whUatntNoncta \
    UdJSys2T0fw+Idy/GS0xd0dWIviAdKTHrFuz3+9MTD8ZRTU1bsWl3BnS7ZMeEoOe \
    xFZeb6OCBPQwggTwMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjALBgNV \
    HQ8EBAMCB4AwggOzBgNVHREEggOqMIIDpoIMKi5nb29nbGUuY29tgg0qLmFuZHJv \
    aWQuY29tghYqLmFwcGVuZ2luZS5nb29nbGUuY29tghIqLmNsb3VkLmdvb2dsZS5j \
    b22CDiouZ2NwLmd2dDIuY29tghYqLmdvb2dsZS1hbmFseXRpY3MuY29tggsqLmdv \
    b2dsZS5jYYILKi5nb29nbGUuY2yCDiouZ29vZ2xlLmNvLmlugg4qLmdvb2dsZS5j \
    by5qcIIOKi5nb29nbGUuY28udWuCDyouZ29vZ2xlLmNvbS5hcoIPKi5nb29nbGUu \
    Y29tLmF1gg8qLmdvb2dsZS5jb20uYnKCDyouZ29vZ2xlLmNvbS5jb4IPKi5nb29n \
    bGUuY29tLm14gg8qLmdvb2dsZS5jb20udHKCDyouZ29vZ2xlLmNvbS52boILKi5n \
    b29nbGUuZGWCCyouZ29vZ2xlLmVzggsqLmdvb2dsZS5mcoILKi5nb29nbGUuaHWC \
    CyouZ29vZ2xlLml0ggsqLmdvb2dsZS5ubIILKi5nb29nbGUucGyCCyouZ29vZ2xl \
    LnB0ghIqLmdvb2dsZWFkYXBpcy5jb22CDyouZ29vZ2xlYXBpcy5jboIUKi5nb29n \
    bGVjb21tZXJjZS5jb22CESouZ29vZ2xldmlkZW8uY29tggwqLmdzdGF0aWMuY26C \
    DSouZ3N0YXRpYy5jb22CCiouZ3Z0MS5jb22CCiouZ3Z0Mi5jb22CFCoubWV0cmlj \
    LmdzdGF0aWMuY29tggwqLnVyY2hpbi5jb22CECoudXJsLmdvb2dsZS5jb22CFiou \
    eW91dHViZS1ub2Nvb2tpZS5jb22CDSoueW91dHViZS5jb22CFioueW91dHViZWVk \
    dWNhdGlvbi5jb22CCyoueXRpbWcuY29tghphbmRyb2lkLmNsaWVudHMuZ29vZ2xl \
    LmNvbYILYW5kcm9pZC5jb22CG2RldmVsb3Blci5hbmRyb2lkLmdvb2dsZS5jboIc \
    ZGV2ZWxvcGVycy5hbmRyb2lkLmdvb2dsZS5jboIEZy5jb4IGZ29vLmdsghRnb29n \
    bGUtYW5hbHl0aWNzLmNvbYIKZ29vZ2xlLmNvbYISZ29vZ2xlY29tbWVyY2UuY29t \
    ghhzb3VyY2UuYW5kcm9pZC5nb29nbGUuY26CCnVyY2hpbi5jb22CCnd3dy5nb28u \
    Z2yCCHlvdXR1LmJlggt5b3V0dWJlLmNvbYIUeW91dHViZWVkdWNhdGlvbi5jb20w \
    aAYIKwYBBQUHAQEEXDBaMCsGCCsGAQUFBzAChh9odHRwOi8vcGtpLmdvb2dsZS5j \
    b20vR0lBRzIuY3J0MCsGCCsGAQUFBzABhh9odHRwOi8vY2xpZW50czEuZ29vZ2xl \
    LmNvbS9vY3NwMB0GA1UdDgQWBBT9WhKAC80EX/JNWSgDcCNXGUD4NzAMBgNVHRMB \
    Af8EAjAAMB8GA1UdIwQYMBaAFErdBhYbvPZotXb1gba7Yhq6WoEvMCEGA1UdIAQa \
    MBgwDAYKKwYBBAHWeQIFATAIBgZngQwBAgIwMAYDVR0fBCkwJzAloCOgIYYfaHR0 \
    cDovL3BraS5nb29nbGUuY29tL0dJQUcyLmNybDANBgkqhkiG9w0BAQsFAAOCAQEA \
    Icipac4Cm3i9wDM6dVE6d1So6HBDSrJsjO+MOvF2BVeXSz7kZE/9qNAnb/gPiNDw \
    ak11ebI6WPWzovsKR8rFRpCFosWAOW+0owY/mDDhhc+cjpObpOqWX8LMJK4LUQhr \
    f7WE2OboHZgBLpiiuWnliPWFP4Zc8tkHGkCE+H67cjjA8EbVjFoTFyGb3E9d+fy4 \
    vjwte/a2zOgtb9a798PXPFh4DPEANr24yIo4Og/TPu/cGOCOn8dmfgnH1Dyje8Pr \
    79IIGKw/d9jpAQhlFZYKSyTzLfHzv/7dhQuIUkAy3t0wuDC3m+TMILHRi1YPvnbp \
    W5J8hNoySW6YP8QIQhOrPg==";
    
    NSString *cert1 = @"\
    MIID8DCCAtigAwIBAgIDAjqSMA0GCSqGSIb3DQEBCwUAMEIxCzAJBgNVBAYTAlVT \
    MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i \
    YWwgQ0EwHhcNMTUwNDAxMDAwMDAwWhcNMTcxMjMxMjM1OTU5WjBJMQswCQYDVQQG \
    EwJVUzETMBEGA1UEChMKR29vZ2xlIEluYzElMCMGA1UEAxMcR29vZ2xlIEludGVy \
    bmV0IEF1dGhvcml0eSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB \
    AJwqBHdc2FCROgajguDYUEi8iT/xGXAaiEZ+4I/F8YnOIe5a/mENtzJEiaB0C1NP \
    VaTOgmKV7utZX8bhBYASxF6UP7xbSDj0U/ck5vuR6RXEz/RTDfRK/J9U3n2+oGtv \
    h8DQUB8oMANA2ghzUWx//zo8pzcGjr1LEQTrfSTe5vn8MXH7lNVg8y5Kr0LSy+rE \
    ahqyzFPdFUuLH8gZYR/Nnag+YyuENWllhMgZxUYi+FOVvuOAShDGKuy6lyARxzmZ \
    EASg8GF6lSWMTlJ14rbtCMoU/M4iarNOz0YDl5cDfsCx3nuvRTPPuj5xt970JSXC \
    DTWJnZ37DhF5iR43xa+OcmkCAwEAAaOB5zCB5DAfBgNVHSMEGDAWgBTAephojYn7 \
    qwVkDBF9qn1luMrMTjAdBgNVHQ4EFgQUSt0GFhu89mi1dvWBtrtiGrpagS8wDgYD \
    VR0PAQH/BAQDAgEGMC4GCCsGAQUFBwEBBCIwIDAeBggrBgEFBQcwAYYSaHR0cDov \
    L2cuc3ltY2QuY29tMBIGA1UdEwEB/wQIMAYBAf8CAQAwNQYDVR0fBC4wLDAqoCig \
    JoYkaHR0cDovL2cuc3ltY2IuY29tL2NybHMvZ3RnbG9iYWwuY3JsMBcGA1UdIAQQ \
    MA4wDAYKKwYBBAHWeQIFATANBgkqhkiG9w0BAQsFAAOCAQEACE4Ep4B/EBZDXgKt \
    10KA9LCO0q6z6xF9kIQYfeeQFftJf6iZBZG7esnWPDcYCZq2x5IgBzUzCeQoY3IN \
    tOAynIeYxBt2iWfBUFiwE6oTGhsypb7qEZVMSGNJ6ZldIDfM/ippURaVS6neSYLA \
    EHD0LPPsvCQk0E6spdleHm2SwaesSDWB+eXknGVpzYekQVA/LlelkVESWA6MCaGs \
    eqQSpSfzmhCXfVUDBvdmWF9fZOGrXW2lOUh1mEwpWjqN0yvKnFUEv/TmFNWArCbt \
    F4mmk2xcpMy48GaOZON9muIAs0nH5Aqq3VuDx3CQRk6+0NtZlmwu9RY23nHMAcIS \
    wSHGFg==";
    
    NSString *cert2 = @"\
    MIIDVDCCAjygAwIBAgIDAjRWMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT \
    MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i \
    YWwgQ0EwHhcNMDIwNTIxMDQwMDAwWhcNMjIwNTIxMDQwMDAwWjBCMQswCQYDVQQG \
    EwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEbMBkGA1UEAxMSR2VvVHJ1c3Qg \
    R2xvYmFsIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2swYYzD9 \
    9BcjGlZ+W988bDjkcbd4kdS8odhM+KhDtgPpTSEHCIjaWC9mOSm9BXiLnTjoBbdq \
    fnGk5sRgprDvgOSJKA+eJdbtg/OtppHHmMlCGDUUna2YRpIuT8rxh0PBFpVXLVDv \
    iS2Aelet8u5fa9IAjbkU+BQVNdnARqN7csiRv8lVK83Qlz6cJmTM386DGXHKTubU \
    1XupGc1V3sjs0l44U+VcT4wt/lAjNvxm5suOpDkZALeVAjmRCw7+OC7RHQWa9k0+ \
    bw8HHa8sHo9gOeL6NlMTOdReJivbPagUvTLrGAMoUgRx5aszPeE4uwc2hGKceeoW \
    MPRfwCvocWvk+QIDAQABo1MwUTAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTA \
    ephojYn7qwVkDBF9qn1luMrMTjAfBgNVHSMEGDAWgBTAephojYn7qwVkDBF9qn1l \
    uMrMTjANBgkqhkiG9w0BAQUFAAOCAQEANeMpauUvXVSOKVCUn5kaFOSPeCpilKIn \
    Z57QzxpeR+nBsqTP3UEaBU6bS+5Kb1VSsyShNwrrZHYqLizz/Tt1kL/6cdjHPTfS \
    tQWVYrmm3ok9Nns4d0iXrKYgjy6myQzCsplFAMfOEVEiIuCl6rYVSAlk6l5PdPcF \
    PseKUgzbFbS9bZvlxrFUaKnjaZC2mqUPuLk/IH2uSrW4nOQdtqvmlKXBx4Ot2/Un \
    hw4EbNX/3aBd7YdStysVAq45pmp06drE57xNNB6pXE0zX5IJL4hmXXeXxx12E6nV \
    5fEWCRE11azbJHFwLJhWC9kXtNHjUStedejV0NxPNO3CBWaAocvmMw==";
    
    return @[[[NSData alloc] initWithBase64EncodedString:cert0 options:NSDataBase64DecodingIgnoreUnknownCharacters],
             [[NSData alloc] initWithBase64EncodedString:cert1 options:NSDataBase64DecodingIgnoreUnknownCharacters],
             [[NSData alloc] initWithBase64EncodedString:cert2 options:NSDataBase64DecodingIgnoreUnknownCharacters]];
}

- (NSArray *)invalidCertificateChain
{
    NSString *cert0 = @"\
    MIIHXDCCBkSgAwIBAgIIU0E9kXjSjCcwDQYJKoZIhvcNAQELBQAwSTELMAkGA1UE \
    BhMCVVMxEzARBgNVBAoTCkdvb2dsZSBJbmMxJTAjBgNVBAMTHEdvb2dsZSBJbnRl \
    cm5ldCBBdXRob3JpdHkgRzIwHhcNMTcwNDI3MDgzMDAwWhcNMTcwNzIwMDgzMDAw \
    WjBmMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTEWMBQGA1UEBwwN \
    TW91bnRhaW4gVmlldzETMBEGA1UECgwKR29vZ2xlIEluYzEVMBMGA1UEAwwMKi5n \
    b29nbGUuY29tMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEvU0whUatntNoncta \
    UdJSys2T0fw+Idy/GS0xd0dWIviAdKTHrFuz3+9MTD8ZRTU1bsWl3BnS7ZMeEoOe \
    xFZeb6OCBPQwggTwMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjALBgNV \
    HQ8EBAMCB4AwggOzBgNVHREEggOqMIIDpoIMKi5nb29nbGUuY29tgg0qLmFuZHJv \
    aWQuY29tghYqLmFwcGVuZ2luZS5nb29nbGUuY29tghIqLmNsb3VkLmdvb2dsZS5j \
    b22CDiouZ2NwLmd2dDIuY29tghYqLmdvb2dsZS1hbmFseXRpY3MuY29tggsqLmdv \
    b2dsZS5jYYILKi5nb29nbGUuY2yCDiouZ29vZ2xlLmNvLmlugg4qLmdvb2dsZS5j \
    by5qcIIOKi5nb29nbGUuY28udWuCDyouZ29vZ2xlLmNvbS5hcoIPKi5nb29nbGUu \
    Y29tLmF1gg8qLmdvb2dsZS5jb20uYnKCDyouZ29vZ2xlLmNvbS5jb4IPKi5nb29n \
    bGUuY29tLm14gg8qLmdvb2dsZS5jb20udHKCDyouZ29vZ2xlLmNvbS52boILKi5n \
    b29nbGUuZGWCCyouZ29vZ2xlLmVzggsqLmdvb2dsZS5mcoILKi5nb29nbGUuaHWC \
    CyouZ29vZ2xlLml0ggsqLmdvb2dsZS5ubIILKi5nb29nbGUucGyCCyouZ29vZ2xl \
    LnB0ghIqLmdvb2dsZWFkYXBpcy5jb22CDyouZ29vZ2xlYXBpcy5jboIUKi5nb29n \
    bGVjb21tZXJjZS5jb22CESouZ29vZ2xldmlkZW8uY29tggwqLmdzdGF0aWMuY26C \
    DSouZ3N0YXRpYy5jb22CCiouZ3Z0MS5jb22CCiouZ3Z0Mi5jb22CFCoubWV0cmlj \
    LmdzdGF0aWMuY29tggwqLnVyY2hpbi5jb22CECoudXJsLmdvb2dsZS5jb22CFiou \
    eW91dHViZS1ub2Nvb2tpZS5jb22CDSoueW91dHViZS5jb22CFioueW91dHViZWVk \
    dWNhdGlvbi5jb22CCyoueXRpbWcuY29tghphbmRyb2lkLmNsaWVudHMuZ29vZ2xl \
    LmNvbYILYW5kcm9pZC5jb22CG2RldmVsb3Blci5hbmRyb2lkLmdvb2dsZS5jboIc \
    ZGV2ZWxvcGVycy5hbmRyb2lkLmdvb2dsZS5jboIEZy5jb4IGZ29vLmdsghRnb29n \
    bGUtYW5hbHl0aWNzLmNvbYIKZ29vZ2xlLmNvbYISZ29vZ2xlY29tbWVyY2UuY29t \
    ghhzb3VyY2UuYW5kcm9pZC5nb29nbGUuY26CCnVyY2hpbi5jb22CCnd3dy5nb28u \
    Z2yCCHlvdXR1LmJlggt5b3V0dWJlLmNvbYIUeW91dHViZWVkdWNhdGlvbi5jb20w \
    aAYIKwYBBQUHAQEEXDBaMCsGCCsGAQUFBzAChh9odHRwOi8vcGtpLmdvb2dsZS5j \
    b20vR0lBRzIuY3J0MCsGCCsGAQUFBzABhh9odHRwOi8vY2xpZW50czEuZ29vZ2xl \
    LmNvbS9vY3NwMB0GA1UdDgQWBBT9WhKAC80EX/JNWSgDcCNXGUD4NzAMBgNVHRMB \
    Af8EAjAAMB8GA1UdIwQYMBaAFErdBhYbvPZotXb1gba7Yhq6WoEvMCEGA1UdIAQa \
    MBgwDAYKKwYBBAHWeQIFATAIBgZngQwBAgIwMAYDVR0fBCkwJzAloCOgIYYfaHR0 \
    cDovL3BraS5nb29nbGUuY29tL0dJQUcyLmNybDANBgkqhkiG9w0BAQsFAAOCAQEA \
    Icipac4Cm3i9wDM6dVE6d1So6HBDSrJsjO+MOvF2BVeXSz7kZE/9qNAnb/gPiNDw \
    ak11ebI6WPWzovsKR8rFRpCFosWAOW+0owY/mDDhhc+cjpObpOqWX8LMJK4LUQhr \
    f7WE2OboHZgBLpiiuWnliPWFP4Zc8tkHGkCE+H67cjjA8EbVjFoTFyGb3E9d+fy4 \
    vjwte/a2zOgtb9a798PXPFh4DPEANr24yIo4Og/TPu/cGOCOn8dmfgnH1Dyje8Pr \
    79IIGKw/d9jpAQhlFZYKSyTzLfHzv/7dhQuIUkAy3t0wuDC3m+TMILHRi1YPvnbp \
    W5J8hNoySW6YP8QIQhOrPg==";
    
    return @[[[NSData alloc] initWithBase64EncodedString:cert0 options:NSDataBase64DecodingIgnoreUnknownCharacters]];
}

- (SecTrustRef)serverTrustWithCertificateChain:(NSArray *)certificateChain
{
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    
    NSMutableArray *certificates = [NSMutableArray array];
    
    for (NSData *certificateData in certificateChain) {
        SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (CFDataRef)certificateData);
        [certificates addObject:CFBridgingRelease(certificate)];
    }
    
    SecTrustRef trust;
    SecTrustCreateWithCertificates((CFArrayRef)certificates, policy, &trust);
    
    CFRelease(policy);
    
    return trust;
}

- (void)dumpCertificateChainForServerTrust:(SecTrustRef)serverTrust
{
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        CFDataRef data = SecCertificateCopyData(certificate);
        
        NSLog(@"certificate %li\n%@", i, [(__bridge NSData *)data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn | NSDataBase64Encoding64CharacterLineLength]);
        
        CFRelease(certificate);
    }
}

- (SecTrustRef)validTrustForProductionHost
{
    return [self serverTrustWithCertificateChain:[self productionCertificateChain]];
}

- (SecTrustRef)validTrustForExternalHost
{
    return [self serverTrustWithCertificateChain:[self externalCertificateChain]];
}

- (SecTrustRef)invalidTrustForExternalHost
{
    return [self serverTrustWithCertificateChain:[self invalidCertificateChain]];
}

- (NSArray<NSString *> *)pinnedHosts
{
    return @[@"prod-nginz-https.wire.com", @"prod-nginz-ssl.wire.com", @"prod-assets.wire.com", @"www.wire.com", @"wire.com"];
}

- (void)testPinnedHostsWithValidCertificateIsTrustedAreTrusted
{
    // given
    SecTrustRef serverTrust = [self validTrustForProductionHost];
    
    // then
    for (NSString *pinnedHost in self.pinnedHosts) {
        XCTAssertTrue(verifyServerTrust(serverTrust, pinnedHost));
    }
    
    CFRelease(serverTrust);
}

- (void)testPinnedHostsAreNotTrustedWithWrongCertificate
{
    // given
    SecTrustRef serverTrust = [self validTrustForExternalHost];
    
    // then
    for (NSString *pinnedHost in self.pinnedHosts) {
        XCTAssertFalse(verifyServerTrust(serverTrust, pinnedHost));
    }
    
    CFRelease(serverTrust);
}

- (void)testExternalHostWithValidCertificateIsTrusted
{
    // given
    XCTestExpectation *trustExpectation = [self expectationWithDescription:@"It should verify the server trust"];

    TestTrustVerificator *trustVerificator = [[TestTrustVerificator alloc] initWithCallback:^(BOOL trusted){
        if (trusted) {
            [trustExpectation fulfill];
        }
    }]; 

    // when
    [trustVerificator verifyURL:[NSURL URLWithString:@"https://www.youtube.com"]];

    // then
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testExternalHostWithInvalidCertificateIsNotTrusted
{
    // given
    SecTrustRef serverTrust = [self invalidTrustForExternalHost];
    
    // then
    XCTAssertFalse(verifyServerTrust(serverTrust, @"https://www.youtube.com"));
    
    CFRelease(serverTrust);
}

@end
