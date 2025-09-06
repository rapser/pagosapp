//
//  Item.swift
//  pagosApp
//
//  Created by miguel tomairo on 5/09/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
