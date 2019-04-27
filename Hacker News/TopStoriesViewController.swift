//
//  MasterViewController.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import UIKit
import SafariServices
import Promises

let MAX_STORIES = 10_000;
let STORIES_PER_PAGE = 30;

class TopStoriesViewController: UITableViewController {

    var allStories = HackerNews.Page()
    var loadedStoryIDs = Set<UInt>()
    var storyPageIndex: UInt = 1
    var pagePromise = Promise(())
    var numPendingPages = 1
    var maxRowToPrefetch = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(userDidRequestRefresh(_:)), for: .valueChanged)
        
        refreshControl!.beginRefreshing()
        refreshStories()
        
        tableView.showsVerticalScrollIndicator = false
        tableView.prefetchDataSource = self
        tableView.register(StoryCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    @objc
    private func userDidRequestRefresh(_ sender: Any) {
        refreshStories()
    }
    
    private func refreshStories() {
        storyPageIndex = 1
        pagePromise = HackerNews.stories(forPage: 1).then { stories in
            self.didLoad(firstPage: stories)
        }
    }
    
    private func didLoad(firstPage stories: HackerNews.Page) {
        numPendingPages -= 1
        
        allStories.removeAll()
        loadedStoryIDs.removeAll()
        
        for story in stories {
            allStories.append(story)
            loadedStoryIDs.insert(story.id)
        }
        
        DispatchQueue.main.async {
            self.refreshControl!.endRefreshing()
            if let indexPaths = self.tableView.indexPathsForVisibleRows {
                self.tableView.reloadRows(at: indexPaths, with: .none)
            }
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MAX_STORIES
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StoryCell
        cell.configure(allStories[optional: indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row >= allStories.count {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else {
            let story = allStories[indexPath.row]
            let safariController = SFSafariViewController(url: HackerNews.readableURL(forStory: story))
            splitViewController!.showDetailViewController(safariController, sender: nil)
        }
    }
}

extension TopStoriesViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        maxRowToPrefetch = max(maxRowToPrefetch, indexPaths.last!.row)
        loadNextPageIfNeeded()
    }
    
    private func loadNextPageIfNeeded() {
        let prefetchStoryCount = allStories.count + numPendingPages * STORIES_PER_PAGE
        if maxRowToPrefetch >= prefetchStoryCount {
            numPendingPages += 1
            storyPageIndex += 1
            let newPageIndex = storyPageIndex
            let newPagePromise = HackerNews.stories(forPage: newPageIndex)
            pagePromise = all(pagePromise, newPagePromise).then { _, stories in
                self.didLoad(stories: stories, forPageIndex: newPageIndex)
            }
        }
    }
    
    private func didLoad(stories: HackerNews.Page, forPageIndex pageIndex: UInt) {
        numPendingPages -= 1
        
        if pageIndex > storyPageIndex {
            return // Refresh has occurred. Currently there is no way to cancel a promise
        }
        
        let startCount = allStories.count
        for story in stories {
            if loadedStoryIDs.insert(story.id).inserted {
                allStories.append(story)
            }
        }
        let newStoryRange = startCount..<allStories.count
        DispatchQueue.main.async {
            if var indexPaths = self.tableView.indexPathsForVisibleRows {
                indexPaths = indexPaths.filter { newStoryRange.contains($0.row) }
                if indexPaths.count > 0 {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadRows(at: indexPaths, with: .none)
                    }
                }
            }
        }
        
        loadNextPageIfNeeded();
    }
}
