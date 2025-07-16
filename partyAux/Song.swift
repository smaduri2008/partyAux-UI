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

    init(from dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
        self.albumArt = dict["album_art"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.album = dict["album"] as? String ?? ""
        self.artist = dict["artist"] as? String ?? ""
    }
}

