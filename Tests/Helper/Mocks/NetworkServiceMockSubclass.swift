//
//  NetworkServiceMockSubclass.swift
//  Hyperspace
//
//  Created by Adam Brzozowski on 1/31/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
@testable import Hyperspace

class NetworkServiceMockSubclass: TransportService {
    
    private(set) var initWithNetworkActivityControllerCalled = false
    
    override init(session: NetworkSession = URLSession.shared, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
        initWithNetworkActivityControllerCalled = true
        super.init(session: session, networkActivityIndicatable: networkActivityIndicatable)
    }
}
