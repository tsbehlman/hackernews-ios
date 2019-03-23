//
//  Story.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import Foundation

struct Story: Decodable {
    let id: UInt
    let url: String
    let title: String
    let descendants: UInt
    let domain: String
}
