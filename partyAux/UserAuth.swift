//
//  UserAuth.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import Foundation

class UserAuth: ObservableObject{
    
    @Published var jwt: String?
    @Published var email: String = ""
    @Published var otp: String = ""
    @Published var username: String = ""
    @Published var needsUser: Bool = false
    @Published var authenticated: Bool = false
    @Published var showOTPView: Bool = false
    
    let url = "http://35.208.64.59"
    let jwtKey = "auth_token"
    
    init() {
        loadJWT()
    }
    
    
    func sendOTP() //add code to make sure the email is valid -> add animation/feature on front end for that too
    {
        print("sending otp")
        guard let urlRequest = URL(string: url + "/send-otp") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["email": email])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request){ _, response, _ in
            print("sent otp | response: \(response.debugDescription)")
        }.resume()
                
    }
    
    func login()
    {
        print("logging in")
        guard let urlRequest = URL(string: url + "/login") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue( "application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["email": email, "otp": otp])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request){data, response, _ in
            guard let data = data,
                    let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let jwt = jsonData["jwt"] as? String else { return }
            DispatchQueue.main.async {
                self.jwt = jwt
                self.saveJWT(jwt: jwt)
                self.checkIfUserExists()
            }
        }.resume()
    }
    
    func checkIfUserExists()
    {
        print("checking if user exists")
        guard let urlRequest = URL(string: url + "/exists") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue( "application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["jwt": jwt])
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request){data, response, _ in
            guard let data = data,
                  let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let userExists = jsonData["exists"] as? Bool else { return }
            DispatchQueue.main.async {
                self.needsUser = !userExists
                self.authenticated = userExists
            }
        }.resume()
    }
    
    func signUp()
    {
        print("creating user")
        guard let urlRequest = URL(string: url + "/create-signup") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try? JSONSerialization.data(withJSONObject: ["jwt": jwt, "username": username])
        request.httpBody = data
        //print("starting status retrieval")
        URLSession.shared.dataTask(with: request){data, response, _ in
            guard let data = data,
                  let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = jsonData["status"] as? String else {
                print("failed")
                return
            }
            
            //print("getting status")
            DispatchQueue.main.async {  //create a method in UI to allow user to re enter username if already taken
                if status == "Account created successfully"{
                    self.needsUser = false
                    self.authenticated = true
                    print("account created")
                }
                else if status == "User already exists" || status == "Username already exists"{
                    print("username exists/account already exists with that email")
                }
                else {
                    print("could not create account \(status)")
                }
            }
        }.resume()
        
    }
    
    func saveJWT(jwt: String) {
        UserDefaults.standard.set(jwt, forKey: jwtKey)
    }

        

    func loadJWT() {
        if let storedJWT = UserDefaults.standard.string(forKey: jwtKey) {
            self.jwt = storedJWT
            self.authenticated = true
        }
    }
}
