import Foundation

// MARK: - URLProtocol Mock for WebSocket Testing

/// Mock URLProtocol to intercept and mock WebSocket connections
class MockURLProtocol: URLProtocol {

    // MARK: - Static Properties

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var mockResponses: [String: (statusCode: Int, data: Data)] = [:]
    static var mockError: Error?

    // MARK: - URLProtocol Overrides

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Check for mock error
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        // Check for custom request handler
        if let handler = MockURLProtocol.requestHandler {
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
            return
        }

        // Check for URL-based mock responses
        if let url = request.url?.absoluteString,
           let mockResponse = MockURLProtocol.mockResponses[url] {
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: mockResponse.statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mockResponse.data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // Default: return empty success
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // Clean up if needed
    }

    // MARK: - Helper Methods

    static func reset() {
        requestHandler = nil
        mockResponses.removeAll()
        mockError = nil
    }

    static func setMockResponse(for url: String, statusCode: Int, data: Data) {
        mockResponses[url] = (statusCode: statusCode, data: data)
    }

    static func setMockError(_ error: Error) {
        mockError = error
    }
}

// MARK: - WebSocket Message Helpers

struct WebSocketMessageHelper {

    static func createJoinMessage(deviceId: String) -> [String: Any] {
        return [
            "topic": "hr:\(deviceId)",
            "event": "phx_join",
            "payload": [:],
            "ref": "1"
        ] as [String: Any]
    }

    static func createLeaveMessage(deviceId: String) -> [String: Any] {
        return [
            "topic": "hr:\(deviceId)",
            "event": "phx_leave",
            "payload": [:],
            "ref": Date().timeIntervalSince1970.description
        ] as [String: Any]
    }

    static func createHeartbeatMessage() -> [String: Any] {
        return [
            "event": "ping",
            "payload": ["timestamp": Int(Date().timeIntervalSince1970 * 1000)]
        ] as [String: Any]
    }

    static func createHeartRateUpdateMessage(heartRate: Int) -> [String: Any] {
        return [
            "event": "hr_update",
            "payload": ["hr": heartRate]
        ] as [String: Any]
    }

    static func createReplyMessage(status: String = "ok") -> [String: Any] {
        return [
            "event": "phx_reply",
            "payload": ["status": status],
            "ref": "1"
        ] as [String: Any]
    }

    static func messageToJSON(_ message: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }

    static func messageToData(_ message: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: message)
    }
}

// MARK: - Test Expectations Helper

class TestExpectationHelper {

    static func waitForAsyncOperation(
        timeout: TimeInterval = 1.0,
        operation: @escaping () -> Void
    ) {
        let expectation = XCTestExpectation(description: "Async operation")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            operation()
            expectation.fulfill()
        }

        XCTWaiter().wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - XCTest Import

import XCTest
