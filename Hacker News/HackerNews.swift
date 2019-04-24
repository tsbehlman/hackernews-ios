//
//  HackerNews.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import Foundation
import Promises

class HackerNews {
    static let baseURL = URL(string:"http://tbehlman.com/hackernews/")!;
    
    typealias Page = [Story]
    
    static func stories(forPage pageIndex: UInt) -> Promise<Page> {
        let pageURL = baseURL.appendingPathComponent("page/\(pageIndex)")
        return fetch(url: pageURL).then { data in
            return try JSONDecoder().decode([Story].self, from: data)
        }
    }
    
    static func readableURL(forStory story: Story) -> URL {
        return baseURL.appendingPathComponent("view/\(story.id)")
    }
}
