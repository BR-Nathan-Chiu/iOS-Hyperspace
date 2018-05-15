//
//  MockDecodableContainer.swift
//  Hyperspace_Tests
//
//  Created by Will McGinty on 12/5/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

struct MockObject: Decodable {
    let title: String
    let subtitle: String
    
    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

struct MockDate: Decodable {
    let date: Date
}

struct MockDecodableContainer: DecodableContainer {
    var element: MockObject
    
    private enum CodingKeys: String, CodingKey {
        case element = "root_key"
    }
}

struct MockArrayDecodableContainer: DecodableContainer {
    var element: [MockObject]
    
    private enum CodingKeys: String, CodingKey {
        case element = "root_key"
    }
}
