//
//  NetworkManager.swift
//  partyAux
//
//  Created by GitHub Copilot
//

import Foundation

/// Centralized network manager with optimized configuration for fast API requests
class NetworkManager {
    
    // MARK: - Singleton
    static let shared = NetworkManager()
    
    // MARK: - Properties
    private let session: URLSession
    private let baseURL = "https://api.partyaux.party"
    
    // MARK: - Initialization
    private init() {
        // Create optimized URLSession configuration
        let configuration = URLSessionConfiguration.default
        
        // Reduce timeouts significantly for faster failure detection
        configuration.timeoutIntervalForRequest = 10 // 10 seconds for request
        configuration.timeoutIntervalForResource = 15 // 15 seconds for entire resource
        
        // Enable HTTP pipelining for better performance
        configuration.httpShouldUsePipelining = true
        
        // Increase maximum connections per host
        configuration.httpMaximumConnectionsPerHost = 10
        
        // Optimize connection behavior
        configuration.waitsForConnectivity = false // Fail fast if no connectivity
        
        // Cache policy - don't cache API responses
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil // Disable cache for API calls
        
        // Allow cellular access
        configuration.allowsCellularAccess = true
        
        // HTTP/2 support (if server supports it)
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Connection": "keep-alive"
        ]
        
        // Create session with configuration
        self.session = URLSession(configuration: configuration)
        
        print("✅ NetworkManager initialized with optimized configuration")
    }
    
    // MARK: - Public Methods
    
    /// Perform a POST request with JSON body
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/login")
    ///   - body: Dictionary to be sent as JSON
    ///   - completion: Completion handler with optional response dictionary
    func post(endpoint: String, body: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        
        // Construct URL
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Invalid URL: \(baseURL + endpoint)")
            completion(nil)
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        
        // Set request-specific timeout (shorter for faster operations)
        request.timeoutInterval = 10
        
        // Serialize body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Failed to serialize JSON body: \(error)")
            completion(nil)
            return
        }
        
        let startTime = Date()
        
        // Perform request
        let task = session.dataTask(with: request) { data, response, error in
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Handle errors
            if let error = error {
                print("❌ Network error for \(endpoint) (took \(String(format: "%.2f", elapsed))s): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Log response time
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ \(endpoint) - Status: \(httpResponse.statusCode) - Time: \(String(format: "%.2f", elapsed))s")
            }
            
            // Check for data
            guard let data = data else {
                print("❌ No data received from \(endpoint)")
                completion(nil)
                return
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(json)
                } else {
                    print("❌ Response is not a JSON dictionary for \(endpoint)")
                    completion(nil)
                }
            } catch {
                print("❌ JSON parsing failed for \(endpoint): \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(responseString)")
                }
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    /// Perform a GET request
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - completion: Completion handler with optional data
    func get(endpoint: String, completion: @escaping (Data?) -> Void) {
        
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Invalid URL: \(baseURL + endpoint)")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.timeoutInterval = 10
        
        let startTime = Date()
        
        let task = session.dataTask(with: request) { data, response, error in
            let elapsed = Date().timeIntervalSince(startTime)
            
            if let error = error {
                print("❌ Network error for \(endpoint) (took \(String(format: "%.2f", elapsed))s): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ \(endpoint) - Status: \(httpResponse.statusCode) - Time: \(String(format: "%.2f", elapsed))s")
            }
            
            completion(data)
        }
        
        task.resume()
    }
    
    /// Perform a GET request that expects JSON array response
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - completion: Completion handler with optional JSON array
    func getArray(endpoint: String, completion: @escaping ([[String: Any]]?) -> Void) {
        
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Invalid URL: \(baseURL + endpoint)")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.timeoutInterval = 10
        
        let startTime = Date()
        
        let task = session.dataTask(with: request) { data, response, error in
            let elapsed = Date().timeIntervalSince(startTime)
            
            if let error = error {
                print("❌ Network error for \(endpoint) (took \(String(format: "%.2f", elapsed))s): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ \(endpoint) - Status: \(httpResponse.statusCode) - Time: \(String(format: "%.2f", elapsed))s")
            }
            
            guard let data = data else {
                print("❌ No data received from \(endpoint)")
                completion(nil)
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(jsonArray)
                } else {
                    print("❌ Response is not a JSON array for \(endpoint)")
                    completion(nil)
                }
            } catch {
                print("❌ JSON parsing failed for \(endpoint): \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    /// Get the base URL
    var apiBaseURL: String {
        return baseURL
    }
}
