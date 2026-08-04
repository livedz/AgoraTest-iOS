//
//  AgoraTokenResponse.swift
//  AgoraTest
//
//  Created by MOKSHA on 04/08/26.
//

import Foundation

struct AgoraTokenResponse: Decodable {
    let appId: String
    let token: String
    let channel: String
    let uid: UInt
    let expiresIn: Int
}
