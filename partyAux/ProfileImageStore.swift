//
//  ProfileImageStore.swift
//  partyAux
//
//  Created by Sansky Srivastava on 8/26/25.
//

import UIKit
import Combine

extension Notification.Name {
    static let profileImageUpdated = Notification.Name("profileImageUpdated")
}

final class ProfileImageStore {
    static let shared = ProfileImageStore()
    private init() {}

    private var images: [String: UIImage] = [:] // email -> profile image

    func save(_ image: UIImage, for email: String) {
        images[email] = image
        NotificationCenter.default.post(name: .profileImageUpdated, object: email)
    }

    func load(for email: String) -> UIImage? {
        return images[email]
    }
}
