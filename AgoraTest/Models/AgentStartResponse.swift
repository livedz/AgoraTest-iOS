//
//  AgentStartResponse.swift
//  AgoraTest
//
//  Created by MOKSHA on 05/08/26.
//

import Foundation

struct AgentStartResponse: Decodable {
    let status: String
    let channel: String
    let agora: AgoraAgentInfo
}

struct AgoraAgentInfo: Decodable {
    let agentId: String
    let createTs: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case createTs = "create_ts"
        case status
    }
}
