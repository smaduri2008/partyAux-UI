//
//  UserAuth.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import Foundation
import Combine

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidResponse
    case networkError(String)
    case userExists
    case usernameExists
    case signUpFailed(String)
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let message):
            return message
        case .userExists:
            return "Account already exists with that email"
        case .usernameExists:
            return "Username is already taken"
        case .signUpFailed(let reason):
            return "Sign up failed: \(reason)"
        case .updateFailed:
            return "Failed to update username"
        }
    }
}

// MARK: - Sign Up Result

enum SignUpResult {
    case success
    case userExists
    case usernameExists
    case failed(String)
}

// MARK: - UserAuth

final class UserAuth: ObservableObject {
    
    // MARK: - Storage Keys
    
    private enum StorageKey: String, CaseIterable {
        case jwt = "auth_token"
        case email = "user_email"
        case username = "user_username"
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var jwt: String?
    @Published var email: String = ""
    @Published var otp: String = ""
    @Published var username: String = "" {
        didSet { save(username, for: .username) }
    }
    @Published private(set) var needsUser: Bool = false
    @Published private(set) var authenticated: Bool = false
    @Published var showOTPView: Bool = false
    
    // MARK: - Computed Properties
    
    var isLoggedIn: Bool { authenticated && !needsUser }
    var hasValidToken: Bool { jwt?.isEmpty == false }
    
    // MARK: - Private Properties
    
    private let storage: UserDefaults
    private let network: NetworkManager
    
    #if DEBUG
    private var isLoggingEnabled = true
    #else
    private var isLoggingEnabled = false
    #endif
    
    // MARK: - Initialization
    
    init(storage: UserDefaults = .standard, network: NetworkManager = .shared) {
        self.storage = storage
        self.network = network
        restoreSession()
    }
    
    // MARK: - Session Restoration
    
    private func restoreSession() {
        jwt = load(.jwt)
        
        // Avoid triggering didSet during init by setting backing values
        let storedEmail = load(.email) ?? ""
        let storedUsername = load(.username) ?? ""
        
        email = storedEmail
        username = storedUsername
        authenticated = hasValidToken
        
        log("Session restored - authenticated: \(authenticated)")
    }
    
    // MARK: - Authentication Methods
    
    func sendOTP(completion: ((Bool) -> Void)? = nil) {
        log("Sending OTP to: \(email)")
        
        network.post(endpoint: "/send-otp", body: ["email": email]) { [weak self] response in
            let success = response != nil
            self?.log("OTP sent: \(success)")
            DispatchQueue.main.async {
                completion?(success)
            }
        }
    }
    
    func login(completion: ((Bool) -> Void)? = nil) {
        log("Attempting login")
        
        network.post(endpoint: "/login", body: ["email": email, "otp": otp]) { [weak self] response in
            guard let self = self,
                  let data = response,
                  let token = data["jwt"] as? String else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            
            DispatchQueue.main.async {
                self.setToken(token)
                self.save(self.email, for: .email)
                self.checkIfUserExists { _ in
                    completion?(true)
                }
            }
        }
    }
    
    func checkIfUserExists(completion: ((Bool) -> Void)? = nil) {
        guard let token = jwt else {
            completion?(false)
            return
        }
        
        log("Checking user existence")
        
        network.post(endpoint: "/exists", body: ["jwt": token]) { [weak self] response in
            guard let self = self,
                  let data = response,
                  let exists = data["exists"] as? Bool else {
                self?.log("Failed to parse /exists response")
                DispatchQueue.main.async { completion?(false) }
                return
            }
            
            let serverUsername = data["username"] as? String
            
            DispatchQueue.main.async {
                self.handleUserExistsResponse(exists: exists, serverUsername: serverUsername)
                completion?(exists)
            }
        }
    }
    
    private func handleUserExistsResponse(exists: Bool, serverUsername: String?) {
        needsUser = !exists
        authenticated = exists
        
        if let name = serverUsername, !name.isEmpty {
            username = name
        } else if !exists {
            username = ""
        }
        // If exists but no server username, keep stored username
        
        log("User exists: \(exists), username: \(username)")
    }
    
    // MARK: - Sign Up
    
    func signUp(completion: ((SignUpResult) -> Void)? = nil) {
        guard let token = jwt else {
            completion?(.failed("No authentication token"))
            return
        }
        
        log("Creating user account")
        
        network.post(endpoint: "/create-signup", body: ["jwt": token, "username": username]) { [weak self] response in
            guard let self = self,
                  let data = response,
                  let status = data["status"] as? String else {
                DispatchQueue.main.async { completion?(.failed("Invalid response")) }
                return
            }
            
            DispatchQueue.main.async {
                let result = self.handleSignUpResponse(status: status)
                completion?(result)
            }
        }
    }
    
    private func handleSignUpResponse(status: String) -> SignUpResult {
        switch status {
        case "Account created successfully":
            needsUser = false
            authenticated = true
            log("Account created successfully")
            return .success
            
        case "User already exists":
            log("User already exists")
            return .userExists
            
        case "Username already exists":
            log("Username already exists")
            return .usernameExists
            
        default:
            log("Sign up failed: \(status)")
            return .failed(status)
        }
    }
    
    // MARK: - Username Update
    
    func updateUsername(_ newUsername: String, completion: @escaping (Bool) -> Void) {
        guard let token = jwt else {
            completion(false)
            return
        }
        
        network.post(endpoint: "/update-username", body: ["jwt": token, "username": newUsername]) { [weak self] response in
            let success = response?["success"] as? Bool ?? false
            
            DispatchQueue.main.async {
                if success {
                    self?.username = newUsername
                }
                completion(success)
            }
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        log("Logging out")
        
        // Clear all stored data
        clearStorage()
        
        // Reset state
        jwt = nil
        email = ""
        otp = ""
        username = ""
        authenticated = false
        needsUser = false
        showOTPView = false
        
        log("Logout complete")
    }
    
    // MARK: - Private Helpers
    
    private func setToken(_ token: String) {
        jwt = token
        authenticated = true
        save(token, for: .jwt)
    }
    
    // MARK: - Storage
    
    private func save(_ value: String?, for key: StorageKey) {
        if let value = value {
            storage.set(value, forKey: key.rawValue)
        } else {
            storage.removeObject(forKey: key.rawValue)
        }
    }
    
    private func load(_ key: StorageKey) -> String? {
        storage.string(forKey: key.rawValue)
    }
    
    private func clearStorage() {
        StorageKey.allCases.forEach { key in
            storage.removeObject(forKey: key.rawValue)
        }
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        guard isLoggingEnabled else { return }
        print("[UserAuth] \(message)")
    }
}
