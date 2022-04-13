//
//  Photos.swift
//  VrtualTourist
//
//  Created by Segnonna Hounsou on 12/04/2022.
//

import Foundation

struct PhotoResponse:Codable{
    let photos: Photos
}

struct Photos: Codable{
    let pages: Int
    let photo:[Photo]
}
struct Photo: Codable{
    let id: String
    let secret: String
    let server: String
}
