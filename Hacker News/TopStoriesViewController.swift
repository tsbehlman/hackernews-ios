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

class TopStoriesViewController: UITableViewController {

    var allStories = HackerNews.Page()
    var loadedStoryIDs = Set<UInt>()
    var storyPageIndex: UInt = 1
    var isLoadingData = false
    var pagePromise = Promise(())

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
        isLoadingData = true
        storyPageIndex = 1
        HackerNews.stories(forPage: 1).then { stories in
            self.isLoadingData = false
            
            self.allStories.removeAll()
            self.allStories.append(contentsOf: stories)
            self.loadedStoryIDs.removeAll()
            
            DispatchQueue.main.async {
                self.refreshControl!.endRefreshing()
                if let indexPaths = self.tableView.indexPathsForVisibleRows {
                    self.tableView.reloadRows(at: indexPaths, with: .none)
                }
            }
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10000
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StoryCell
        if indexPath.row < allStories.count {
            let story = allStories[indexPath.row]
            cell.titleLabel.text = story.title
            cell.detailLabel.text = "\(story.descendants) comment\(story.descendants == 1 ? "" : "s")  \(story.domain)"
        } else {
            cell.titleLabel.text = " "
            cell.detailLabel.text = " "
        }
        cell.titleLabel.flex.markDirty()
        cell.detailLabel.flex.markDirty()
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
        if !isLoadingData && indexPaths.contains { $0.row >= self.allStories.count } {
            storyPageIndex += 1
            let newPagePromise = HackerNews.stories(forPage: storyPageIndex)
            pagePromise = all(pagePromise, newPagePromise).then { _, stories in
                self.newPageDidLoad(stories: stories)
            }
        }
    }
    
    private func newPageDidLoad(stories: HackerNews.Page) {
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
    }
}
