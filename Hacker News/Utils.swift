//
//  Utils.swift
//  Hacker News
//
//  Created by Trevor Behlman on 4/24/19.
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

extension Collection {
    subscript(optional index: Self.Index) -> Self.Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
}
