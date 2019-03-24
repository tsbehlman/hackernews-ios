//
//  HackerNews.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import Foundation

class HackerNews {
    static let baseURL = URL(string:"http://tbehlman.com/hackernews/")!;
    
    typealias Page = [Story]
    typealias PageCompletion = (Page?) -> Void
    
    static func stories(forPage pageIndex: UInt, _ completion: @escaping PageCompletion) {
        let pageURL = baseURL.appendingPathComponent("page/\(pageIndex)")
        URLSession.shared.dataTask(with: pageURL) { data, response, error in
            completion(HackerNews.didReceivePageOfStories(data: data, response: response, error: error))
        }.resume()
    }
    
    static func readableURL(forStory story: Story) -> URL {
        return baseURL.appendingPathComponent("view/\(story.id)")
    }
    
    private static func didReceivePageOfStories(data: Data?, response: URLResponse?, error: Error?) -> Page? {
        if let data = data, let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
                do {
                    return try JSONDecoder().decode([Story].self, from: data)
                } catch {}
            }
        }
        
        return nil
    }
}
