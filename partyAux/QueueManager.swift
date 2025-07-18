import Foundation
import UIKit

class QueueManager: ObservableObject {
    @Published var currentSong: [String: Any] = [:]
    @Published var queue: [String: AnyHashable] = [:]
    @Published var queueOrder: [String] = [] // Add this to maintain order
    
    var jwt_auth: String
    var room: String
    public var isInBackground = false

    init(jwt_auth: String, room: String) {
        self.jwt_auth = jwt_auth
        self.room = room
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            print("App entered background")
            self.isInBackground = true
        }
                        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            print("App will enter foreground")
            self.isInBackground = false
        }
    }

    func fetchCurrentSong(completion: @escaping () -> Void) {
        self.currentSong = [:]
        QueueManager.sendPostRequest(body: ["jwt": self.jwt_auth, "room": self.room], endpoint: "/get-current-song") { result in
            if let result = result {
                DispatchQueue.main.async {
                    self.currentSong = result["song"] as? [String: Any] ?? [:]
                    completion()
                }
            } else {
                print("Failed to fetch current song")
                completion()
            }
        }
    }

    func getCurrentSongID() -> String {
        return currentSong["url"] as? String ?? ""
    }
    
    func fetchQueue(completion: @escaping () -> Void) {
        QueueManager.sendPostRequest(body: ["jwt": self.jwt_auth, "room": self.room], endpoint: "/get-queue") { result in
            if let result = result {
                DispatchQueue.main.async {
                    // Clear the existing queue and order
                    self.queue.removeAll()
                    self.queueOrder.removeAll()
                    
                    if let songList = result["queue"] as? [[String: AnyHashable]] {
                        for song in songList {
                            let url = song["url"] as? String ?? UUID().uuidString
                            self.queue[url] = song as AnyHashable
                            self.queueOrder.append(url) // Maintain order
                        }
                    }
                    print("Queue updated with \(self.queue.count) songs")
                    completion()
                }
            } else {
                print("Failed to fetch queue")
                completion()
            }
        }
    }

    func nextSong(completion: @escaping () -> Void) {
        print("jwt: \(self.jwt_auth)")
        
        QueueManager.sendPostRequest(body: ["jwt": self.jwt_auth, "room": self.room], endpoint: "/next-song") { result in
            if let result = result {
                DispatchQueue.main.async {
                    completion()
                }
            } else {
                print("Failed to go to next song")
                completion()
            }
        }
    }

    class func sendPostRequest(body: [String: String], endpoint: String, completion: @escaping ([String: Any]?) -> Void) {
        guard let url = URL(string: "http://35.208.64.59" + endpoint) else {
            print("❌ Invalid URL: http://35.208.64.59\(endpoint)")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 🔥 Network Error
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // 🔍 HTTP Response (to get status code and headers)
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Response Status Code: \(httpResponse.statusCode)")
                print("📦 Headers: \(httpResponse.allHeaderFields)")
            }

            // 📥 Check if data exists
            guard let data = data else {
                print("❌ No data received")
                completion(nil)
                return
            }

            // 🧪 Debug raw response body
            if let rawString = String(data: data, encoding: .utf8) {
                print("📄 Raw response body: \(rawString)")
            }

            // 🧠 Try JSON decoding
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Parsed JSON: \(json)")
                    completion(json)
                } else {
                    print("❌ JSON was not a dictionary")
                    completion(nil)
                }
            } catch {
                print("❌ JSON parsing failed: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
}
