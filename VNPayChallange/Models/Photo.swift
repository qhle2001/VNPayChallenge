//
//  Photo.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 30/9/25.
//

import Foundation

struct Photo: Codable, Identifiable{
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let download_url: String
}
