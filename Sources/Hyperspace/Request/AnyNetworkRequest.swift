//
//  AnyNetworkRequest.swift
//  Hyperspace
//
//  Created by Will McGinty on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

/// A type-erased structure to allow for simple NetworkRequests to be easily created.
public struct AnyNetworkRequest<T>: NetworkRequest {
    
    // MARK: - Properties
    
    public var method: HTTP.Method
    public var url: URL
    public var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
    public var body: Data?
    public var cachePolicy: URLRequest.CachePolicy
    public var timeout: TimeInterval
    private let _transformData: (Data) -> Result<T, AnyError>
    
    // MARK: - Init
    
    public init(method: HTTP.Method,
                url: URL,
                headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                body: Data? = nil,
                cachePolicy: URLRequest.CachePolicy = NetworkRequestDefaults.defaultCachePolicy,
                timeout: TimeInterval = NetworkRequestDefaults.defaultTimeout,
                dataTransformationBlock: @escaping (Data) -> Result<T, AnyError>) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        
        _transformData = dataTransformationBlock
    }
    
    // MARK: - Public
    
    public func transformData(_ data: Data) -> Result<T, AnyError> {
        return _transformData(data)
    }
}

// MARK: - AnyNetworkRequest Default Implementations

extension AnyNetworkRequest where T: Decodable {
    
    public init(method: HTTP.Method,
                url: URL,
                headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                body: Data? = nil,
                cachePolicy: URLRequest.CachePolicy = NetworkRequestDefaults.defaultCachePolicy,
                timeout: TimeInterval = NetworkRequestDefaults.defaultTimeout,
                decoder: JSONDecoder = JSONDecoder()) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        
        _transformData = NetworkRequestDefaults.dataTransformer(for: decoder)
    }
}
