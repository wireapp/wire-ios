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

import XCTest

@testable import WireAPI

final class PinnedKeyTests: XCTestCase {

    func testMatches() throws {
        // GIVEN
        let sut = try PinnedKey(
            key: .publicKey,
            hosts: [
                .equals("foo.example.com"),
                .equals("bar.example.com"),
                .endsWith("example.net")
            ]
        )

        // WHEN, THEN
        XCTAssertTrue(sut.matches(host: "bar.example.com"))
        XCTAssertFalse(sut.matches(host: "something.bar.example.com"))
        XCTAssertTrue(sut.matches(host: "example.net"))
        XCTAssertTrue(sut.matches(host: "something.example.net"))
        XCTAssertFalse(sut.matches(host: "example.net.something"))
    }

}

// MARK: - Test Data

private extension Data {
    static let publicKey = Data(
        base64Encoded:
        """
        MIIE/jCCA+agAwIBAgIQBmeNK7xaqmvwoGsKbGiEuzANBgkqhkiG9w0BAQsFADBNMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5\
        jMScwJQYDVQQDEx5EaWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMTcxMjEyMDAwMDAwWhcNMTkwMjAxMTIwMDAwWjBKMQswCQYDVQ\
        QGEwJDSDEMMAoGA1UEBxMDWnVnMRgwFgYDVQQKEw9XaXJlIFN3aXNzIEdtYkgxEzARBgNVBAMMCioud2lyZS5jb20wggEiMA0GCSqGSIb3DQEBA\
        QUAA4IBDwAwggEKAoIBAQCt5jMFa6+dUph+A01fd1WNSeohW2XhepCcJxjqb+xYzXlNMrRuj0UqczE0A+0PMHpWJG+lmwoR59fymLXklyzi5mK5\
        nzUhJXVurG2myMnnpiN6Z730NxrlyTfmlOFi4rqNny8bqkmJj2ZFj2cZp2J3ipYvu7AB6gifHaY4zsd6kIKHY05d34SNDiwGx+Bv6RatxVCYHO8\
        sc9QOjKSb+b4G8vZ4nWeM82Iz8ah5duYhbVYzeJ+5xgmgP2D5Xk18d8A2tW7bDhhwsNp3QLzk1vxTWyAU2SuA6rOF3/XEeiTW47KOh4tMgcdiSv\
        K9sESZ2Xq/5/YnUQzT4WP2+x4jZNitAgMBAAGjggHbMIIB1zAfBgNVHSMEGDAWgBQPgGEcgjFh1S8o541GOLQs4cbZ4jAdBgNVHQ4EFgQU/0iA8\
        JzB4tDtwNB/3NyYfCtfTZwwHwYDVR0RBBgwFoIKKi53aXJlLmNvbYIId2lyZS5jb20wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUF\
        BwMBBggrBgEFBQcDAjBrBgNVHR8EZDBiMC+gLaArhilodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc3NjYS1zaGEyLWc2LmNybDAvoC2gK4YpaHR\
        0cDovL2NybDQuZGlnaWNlcnQuY29tL3NzY2Etc2hhMi1nNi5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAQEwKjAoBggrBgEFBQcCARYcaHR0cH\
        M6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBAgIwfAYIKwYBBQUHAQEEcDBuMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vyd\
        C5jb20wRgYIKwYBBQUHMAKGOmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJTZWN1cmVTZXJ2ZXJDQS5jcnQwDAYDVR0T\
        AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAc6v6cf/EQmmeGU2nC87F6QgEIAIL3svgabImao3f01QFVxC0XX2Cf9+wofijspqq5Uj80nb04o5\
        HNnZWX1agJmqp8jTYH2hw4+uiwFCld0QEptHMrCwEAyyouf0/cl2dfRv2V8m29W6Qb4+7pc1rEbFLl3fywmjgzpGkr1+cKE7pwkpgKqhulKkE4C\
        DXant0Slj7cvDisSPy/kInJ5uHI29Z/SBCpACyHah6lkdIQyTo4uem1XH6i5UP9sTvCAZl0acHcPsvcJ50LeJvJC7sPNXr60xZYLIK5LIVrSSRh\
        xtOB1WPMbzIQc5bF2LcSjXJNvXA5+RCO79om91mlheqPQ==
        """
    )!
}
