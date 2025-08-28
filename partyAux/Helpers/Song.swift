//
//  Song.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/15/25.
//

import Foundation

struct Song: Equatable {
    var url: String
    var albumArt: String
    var title: String
    var album: String
    var artist: String
    var uuid: String
    var addedBy: String
    var downvotes: [String]

    init(from dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
        self.albumArt = dict["album_art"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.album = dict["album"] as? String ?? ""
        self.artist = dict["artist"] as? String ?? ""
        self.uuid = dict["uuid"] as? String ?? ""
        self.addedBy = dict["added_by"] as? String ?? ""
        self.downvotes = dict["downvotes"] as? [String] ?? []
    }
    
    var downvoteCount: Int {
        return downvotes.count
    }
    
    func hasUserDownvoted(_ userEmail: String) -> Bool {
        return downvotes.contains(userEmail)
    }
}

