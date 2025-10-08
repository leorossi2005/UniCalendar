//
//  Item.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
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
