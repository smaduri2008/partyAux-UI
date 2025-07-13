//
//  RoomManager.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/13/25.
//

import Foundation

class RoomManager: ObservableObject{
    
    private let userData: UserAuth
    @Published var downvotes: Int = 5
    
    init(userData: UserAuth) {
        self.userData = userData
    }
    
    func createRoom()
    {
        var url = userData.url + "/create-room"
        guard let urlRequest = URL(string: url) else {return}
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["jwt": userData.jwt, "max_downvotes": downvotes])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = response["status"] as? String else {
                print("could not join room)")
                return
            }
            DispatchQueue.main.async {
                if status == "Room created successfully"{
                    print("room created")
                }
                else
                {
                    print("room could not be created")
                }
            }
        }.resume()
                
    }
}
