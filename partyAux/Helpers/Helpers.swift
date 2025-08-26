//
//  Helpers.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import Foundation

extension String {
    var digits: [String] {
        return self.map { String($0) }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

