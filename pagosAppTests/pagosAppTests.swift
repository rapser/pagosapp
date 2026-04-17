//
//  pagosAppTests.swift
//  pagosAppTests
//
//  Created by miguel tomairo on 5/09/25.
//

import Foundation
import Testing

struct pagosAppTests {

    @Test func bundleLoads() {
        #expect(Bundle.main.bundleIdentifier != nil)
    }
}
