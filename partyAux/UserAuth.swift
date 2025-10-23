//
//  UserAuth.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import Foundation
import Combine

class UserAuth: ObservableObject {
    
    @Published var jwt: String? {
        didSet {
            saveJWT(jwt: jwt)
        }
    }
    @Published var email: String = "" {
        didSet {
            saveEmail(email: email)
        }
    }
    @Published var otp: String = ""
    @Published var username: String = "" {
        didSet {
            print("Username changed to: '\(username)'")
            saveUsername(username: username)
        }
    }
    @Published var needsUser: Bool = false
    @Published var authenticated: Bool = false
    @Published var showOTPView: Bool = false
    
    let url = "http://api.partyaux.party"
    let jwtKey = "auth_token"
    let emailKey = "user_email"
    let usernameKey = "user_username"
    
    init() {
        loadJWT()
        loadEmail()
        loadUsername()
        // Restore authentication state if JWT is present
        self.authenticated = (self.jwt != nil && !self.jwt!.isEmpty)
    }
    
    func sendOTP() {
        print("sending otp")
        guard let urlRequest = URL(string: url + "/send-otp") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["email": email])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            print("sent otp | response: \(response.debugDescription)")
        }.resume()
    }
    
    func login() {
        print("logging in")
        guard let urlRequest = URL(string: url + "/login") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["email": email, "otp": otp])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data = data,
                  let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let jwt = jsonData["jwt"] as? String else { return }
            DispatchQueue.main.async {
                self.jwt = jwt
                self.authenticated = true
                self.saveJWT(jwt: jwt)
                self.saveEmail(email: self.email)
                self.checkIfUserExists()
            }
        }.resume()
    }
    
    func checkIfUserExists() {
        print("checking if user exists")
        guard let urlRequest = URL(string: url + "/exists") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["jwt": jwt ?? ""])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data = data,
                  let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let userExists = jsonData["exists"] as? Bool else {
                print("Failed to parse response from /exists")
                return
            }
            
            // Handle username separately - it might be null/nil from server
            let serverUsername = jsonData["username"] as? String
            
            DispatchQueue.main.async {
                print("Server response - exists: \(userExists), username: \(serverUsername ?? "nil")")
                
                self.needsUser = !userExists
                self.authenticated = userExists
                
                // Only update username if server provides one
                if let serverUsername = serverUsername, !serverUsername.isEmpty {
                    print("Setting username from server: '\(serverUsername)'")
                    self.username = serverUsername
                } else if userExists {
                    // If user exists but no username from server, keep the stored one
                    print("User exists but no username from server, keeping stored username: '\(self.username)'")
                } else {
                    // User doesn't exist, clear username
                    print("User doesn't exist, clearing username")
                    self.username = ""
                }
            }
        }.resume()
    }
    
    func signUp() {
        print("creating user")
        guard let urlRequest = URL(string: url + "/create-signup") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["jwt": jwt ?? "", "username": username])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data = data,
                  let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = jsonData["status"] as? String else {
                print("failed")
                return
            }
            DispatchQueue.main.async {
                if status == "Account created successfully" {
                    self.needsUser = false
                    self.authenticated = true
                    print("account created with username: '\(self.username)'")
                } else if status == "User already exists" || status == "Username already exists" {
                    print("username exists/account already exists with that email")
                } else {
                    print("could not create account \(status)")
                }
            }
        }.resume()
    }
    
    // MARK: - Persistence
    func saveJWT(jwt: String?) {
        UserDefaults.standard.set(jwt, forKey: jwtKey)
        print("Saved JWT to UserDefaults")
    }
    
    func loadJWT() {
        if let storedJWT = UserDefaults.standard.string(forKey: jwtKey) {
            self.jwt = storedJWT
            print("STORED JWT: \(storedJWT)")
        } else {
            print("No JWT found in UserDefaults")
        }
    }
    
    func saveEmail(email: String) {
        UserDefaults.standard.set(email, forKey: emailKey)
        print("Saved email to UserDefaults: '\(email)'")
    }
    
    func loadEmail() {
        if let storedEmail = UserDefaults.standard.string(forKey: emailKey) {
            self.email = storedEmail
            print("STORED EMAIL: \(self.email)")
        } else {
            print("No email found in UserDefaults")
        }
    }
    
    func saveUsername(username: String) {
        UserDefaults.standard.set(username, forKey: usernameKey)
        print("Saved username to UserDefaults: '\(username)'")
    }
    
    func loadUsername() {
        if let storedUsername = UserDefaults.standard.string(forKey: usernameKey) {
            self.username = storedUsername
            print("STORED USERNAME: '\(storedUsername)'")
        } else {
            print("No username found in UserDefaults")
        }
    }
    
    // Method to update username (for settings screen)
    func updateUsername(_ newUsername: String, completion: @escaping (Bool) -> Void) {
        guard let urlRequest = URL(string: url + "/update-username") else {
            completion(false)
            return
        }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["jwt": jwt ?? "", "username": newUsername])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data = data,
                  let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = jsonData["success"] as? Bool else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                if success {
                    self.username = newUsername
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // Optional: clear user data for logout
    func clearUserData() {
        self.jwt = nil
        self.email = ""
        self.username = ""
        self.authenticated = false
        self.needsUser = false
        self.showOTPView = false
        
        UserDefaults.standard.removeObject(forKey: jwtKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        
        print("Cleared all user data")
    }
    
    func logout() {
        print("🚪 Logging out user")
        
        // Clear JWT from memory and storage
        self.jwt = nil
        UserDefaults.standard.removeObject(forKey: jwtKey)
        
        // Reset authentication state
        self.authenticated = false
        self.needsUser = false
        self.showOTPView = false
        self.otp = ""
        
        print("✅ User logged out successfully")
    }
}
