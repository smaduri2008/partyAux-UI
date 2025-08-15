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
            saveUsername(username: username)
        }
    }
    @Published var needsUser: Bool = false
    @Published var authenticated: Bool = false
    @Published var showOTPView: Bool = false
    
    let url = "http://35.208.64.59"
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
                  let userExists = jsonData["exists"] as? Bool,
                  let username = jsonData["username"] as? String? else { return }
            DispatchQueue.main.async {
                self.needsUser = !userExists
                self.authenticated = userExists
                if let username = username {
                    self.username = username
                    self.saveUsername(username: username)
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
                    self.saveUsername(username: self.username)
                    print("account created")
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
    }
    func loadJWT() {
        if let storedJWT = UserDefaults.standard.string(forKey: jwtKey) {
            self.jwt = storedJWT
            print("STORED JWT: \(storedJWT)")
            print("JWT: \(self.jwt)")
        }
    }
    func saveEmail(email: String) {
        UserDefaults.standard.set(email, forKey: emailKey)
    }
    func loadEmail() {
        if let storedEmail = UserDefaults.standard.string(forKey: emailKey) {
            self.email = storedEmail
            print("STORED EMAIL: \(self.email)")
        }
    }
    func saveUsername(username: String) {
        UserDefaults.standard.set(username, forKey: usernameKey)
    }
    func loadUsername() {
        if let storedUsername = UserDefaults.standard.string(forKey: usernameKey) {
            self.username = storedUsername
        }
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
    }
}
