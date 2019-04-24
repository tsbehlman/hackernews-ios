//
//  HackerNews.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import Foundation
import Promises

func fetch(url: URL) -> Promise<Data> {
    return Promise<Data> { resolve, reject in
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                resolve(data!)
            } else {
                reject(error!)
            }
        }.resume()
    }
}

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
