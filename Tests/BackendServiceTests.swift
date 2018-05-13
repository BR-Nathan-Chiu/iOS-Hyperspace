//
//  BackendServiceTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace
import Result

class BackendServiceTests: XCTestCase {
    
    // MARK: - Typealias
    
    typealias DefaultModel = NetworkRequestTestDefaults.DefaultModel
    
    // MARK: - Properties
    
    private let modelJSONData = NetworkRequestTestDefaults.defaultModelJSONData
    private lazy var defaultSuccessResponse: HTTP.Response = {
        HTTP.Response(code: 200, data: self.modelJSONData)
    }()
    private let defaultRequest = NetworkRequestTestDefaults.DefaultRequest<DefaultModel>()
    
    // MARK: - Tests
    
    func test_AnyError_CreatesSuccessfullyFromNetworkServiceFailure() {
        let failure = NetworkServiceFailure(error: .noInternetConnection, response: nil)
        let anyError = AnyError(networkServiceFailure: failure)
        
        XCTAssertTrue(anyError.error is NetworkServiceError)
        XCTAssertEqual(anyError.error as! NetworkServiceError, .noInternetConnection)
    }
    
    func test_NetworkServiceSuccess_TransformsResponseCorrectly() {
        let model = NetworkRequestTestDefaults.defaultModel
        let mockedResult = NetworkServiceSuccess(data: modelJSONData, response: defaultSuccessResponse)
        
        executeBackendService(mockedNetworkServiceResult: .success(mockedResult), expectingResult: .success(model))
    }
    
    func test_NetworkServiceResponseTransformFailure_GeneratesDataTransformationError() {
        let invalidJSONData = "test".data(using: .utf8)!
        let jsonDecodingError = NSError(domain: NSCocoaErrorDomain, code: 3840, userInfo: nil)
        let response = HTTP.Response(code: 200, data: invalidJSONData)
        let mockedResult = NetworkServiceSuccess(data: invalidJSONData, response: response)
        
        executeBackendService(mockedNetworkServiceResult: .success(mockedResult), expectingResult: .failure(.dataTransformationError(jsonDecodingError)))
    }
    
    func test_NetworkServiceNetworkFailure_GeneratesNetworkError() {
        let response = HTTP.Response(code: 503, data: nil)
        let mockedResult = NetworkServiceFailure(error: .serverError(.serviceUnavailable), response: response)
        
        executeBackendService(mockedNetworkServiceResult: .failure(mockedResult), expectingResult: .failure(.networkError(.serverError(.serviceUnavailable), response)))
    }
    
    func test_ExecutingBackendService_ExecutesUnderlyingNetworkService() {
        let mockedResult = NetworkServiceSuccess(data: modelJSONData, response: defaultSuccessResponse)
        let mockNetworkService = MockNetworkService(responseResult: .success(mockedResult))
        
        let backendService = BackendService(networkService: mockNetworkService)
        backendService.execute(request: defaultRequest) { (_) in }
        
        XCTAssertEqual(mockNetworkService.executeCallCount, 1)
    }
    
    func test_CancellingBackendService_CancelsUnderlyingNetworkService() {
        let mockedResult = NetworkServiceSuccess(data: modelJSONData, response: defaultSuccessResponse)
        let mockNetworkService = MockNetworkService(responseResult: .success(mockedResult))
        
        let backendService = BackendService(networkService: mockNetworkService)
        let request = URLRequest(url: NetworkRequestTestDefaults.defaultURL)
        backendService.cancelTask(for: request)
        
        XCTAssertEqual(mockNetworkService.cancelCallCount, 1)
        XCTAssertEqual(mockNetworkService.lastCancelledURLRequest, request)
    }
    
    func test_BackendServiceDeinit_CancelsAllTasksForUnderlyingNetworkService() {
        let mockedResult = NetworkServiceSuccess(data: modelJSONData, response: defaultSuccessResponse)
        let mockNetworkService = MockNetworkService(responseResult: .success(mockedResult))
        
        var backendService: BackendService? = BackendService(networkService: mockNetworkService)
        backendService = nil
        XCTAssertNil(backendService) // To silence the "variable was written to, but never read" warning. See https://stackoverflow.com/a/32861678/4343618
        
        XCTAssertEqual(mockNetworkService.cancelAllTasksCallCount, 1)
    }
    
    // MARK: - Private
    
    //create a concrete implementation of NetworkServiceFailureInitializable(Error) for testing (aka BackendServiceError...)
    
    private func executeBackendService(mockedNetworkServiceResult: Result<NetworkServiceSuccess, NetworkServiceFailure>,
                                       expectingResult expectedResult: Result<DefaultModel, MockBackendServiceError>,
                                       file: StaticString = #file,
                                       line: UInt = #line) {
        let mockNetworkService = MockNetworkService(responseResult: mockedNetworkServiceResult)
        let backendService = BackendService(networkService: mockNetworkService)
        
        let asyncExpectation = expectation(description: "\(BackendService.self) completion")
        
        let networkRequest = defaultRequest
        backendService.execute(request: networkRequest) { (result) in
            switch (result, expectedResult) {
            case (.success(let resultObject), .success(let expectedObject)):
                XCTAssertEqual(resultObject, expectedObject, file: file, line: line)
            case (.failure(let resultError), .failure(let expectedError)):
                XCTAssertEqual(resultError, expectedError, file: file, line: line)
            default:
                XCTFail("Result '\(result)' not equal to expected result '\(expectedResult)'", file: file, line: line)
            }
            
            asyncExpectation.fulfill()
        }
        
        XCTAssertEqual(mockNetworkService.lastExecutedURLRequest, networkRequest.urlRequest, file: file, line: line)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
