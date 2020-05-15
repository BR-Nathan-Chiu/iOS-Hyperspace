//
//  BackendServiceTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class BackendServiceTests: XCTestCase {
    
    // MARK: - Typealias
    
    typealias DefaultModel = RequestTestDefaults.DefaultModel
    
    // MARK: - Properties
    
    private let modelJSONData = RequestTestDefaults.defaultModelJSONData
    private lazy var defaultSuccessResponse: HTTP.Response = HTTP.Response(code: 200, data: modelJSONData)
    private let defaultRequest: Request<DefaultModel, MockBackendServiceError> = RequestTestDefaults.defaultRequest()
    
    // MARK: - Tests
    
    func test_AnyError_CreatesSuccessfullyFromNetworkServiceFailure() {
        let failure = TransportFailure(error: .init(code: .noInternetConnection), response: nil)
        let anyError = AnyError(transportFailure: failure)
        
        XCTAssertTrue(anyError.error is TransportFailure)
        XCTAssertEqual((anyError.error as! TransportFailure).error, TransportError(code: .noInternetConnection))
    }
    
    func test_NetworkServiceSuccess_TransformsResponseCorrectly() {
        let model = RequestTestDefaults.defaultModel
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        
        executeBackendService(mockedNetworkServiceResult: .success(mockedResult), expectingResult: .success(model))
    }
    
    func test_NetworkServiceResponseTransformFailure_GeneratesDataTransformationError() {
        let invalidJSONData = "test".data(using: .utf8)!
        let jsonDecodingError = NSError(domain: NSCocoaErrorDomain, code: 3840, userInfo: nil)
        let response = HTTP.Response(code: 200, data: invalidJSONData)
        let mockedResult = TransportSuccess(response: response)
        
        executeBackendService(mockedNetworkServiceResult: .success(mockedResult), expectingResult: .failure(.dataTransformationError(jsonDecodingError)))
    }
    
    func test_NetworkServiceNetworkFailure_GeneratesNetworkError() {
        let response = HTTP.Response(code: 503, data: nil)
        let mockedResult = TransportFailure(error: .init(code: .serverError(.serviceUnavailable)), response: response)
        
        executeBackendService(mockedNetworkServiceResult: .failure(mockedResult), expectingResult: .failure(.networkError(.init(code: .serverError(.serviceUnavailable)), response)))
    }
    
    func test_ExecutingBackendService_ExecutesUnderlyingNetworkService() {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
        
        let backendService = BackendService(transportService: mockTransportService)
        backendService.execute(request: defaultRequest) { (_) in }
        
        XCTAssertEqual(mockTransportService.executeCallCount, 1)
    }
    
    func test_CancellingBackendService_CancelsUnderlyingNetworkService() {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
        
        let backendService = BackendService(transportService: mockTransportService)
        let request = URLRequest(url: RequestTestDefaults.defaultURL)
        backendService.cancelTask(for: request)
        
        XCTAssertEqual(mockTransportService.cancelCallCount, 1)
        XCTAssertEqual(mockTransportService.lastCancelledURLRequest, request)
    }
    
    func test_BackendServiceDeinit_CancelsAllTasksForUnderlyingNetworkService() {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
        
        var backendService: BackendService? = BackendService(transportService: mockTransportService)
        backendService = nil
        XCTAssertNil(backendService) // To silence the "variable was written to, but never read" warning. See https://stackoverflow.com/a/32861678/4343618
        
        XCTAssertEqual(mockTransportService.cancelAllTasksCallCount, 1)
    }
    
    // MARK: - Private
    
    //create a concrete implementation of NetworkServiceFailureInitializable(Error) for testing (aka BackendServiceError...)
    
    private func executeBackendService(mockedNetworkServiceResult: TransportResult,
                                       expectingResult expectedResult: Result<DefaultModel, MockBackendServiceError>,
                                       file: StaticString = #file,
                                       line: UInt = #line) {
        let mockTransportService = MockTransportService(responseResult: mockedNetworkServiceResult)
        let backendService = BackendService(transportService: mockTransportService)
        
        let asyncExpectation = expectation(description: "\(BackendService.self) completion")
        
        let request = defaultRequest
        backendService.execute(request: request) { result in            
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
        
        XCTAssertEqual(mockTransportService.lastExecutedURLRequest, request.urlRequest, file: file, line: line)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
