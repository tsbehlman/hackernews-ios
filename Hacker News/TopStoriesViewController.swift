//
//  MasterViewController.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import UIKit
import SafariServices
import FlexLayout
import Promises

class TopStoriesViewController: UITableViewController {

    var stories = [Story]()
    var loadedStoryIDs = Set<UInt>()
    var storyPageIndex: UInt = 1
    var isLoadingData = false
    var pagePromise = Promise(())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(userDidRequestRefresh(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
        
        self.refreshStories()
        
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
        self.refreshStories()
    }
    
    private func refreshStories() {
        isLoadingData = true
        HackerNews.stories(forPage: 1).then { stories in
            self.isLoadingData = false
            
            self.storyPageIndex = 1
            self.stories.removeAll()
            self.stories.append(contentsOf: stories)
            
            DispatchQueue.main.async {
                self.refreshControl!.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10000
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StoryCell
        if indexPath.row < stories.count {
            let story = stories[indexPath.row]
            let commentsLabel = "comment" + (story.descendants == 1 ? "" : "s")
            cell.titleLabel.text = story.title
            cell.detailLabel.text = "\(story.descendants) \(commentsLabel)  \(story.domain)"
        } else {
            cell.titleLabel.text = " "
            cell.detailLabel.text = " "
        }
        cell.titleLabel.flex.markDirty()
        cell.detailLabel.flex.markDirty()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row >= stories.count {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else {
            let story = stories[indexPath.row] as Story
            let safariController = SFSafariViewController(url: HackerNews.readableURL(forStory: story))
            splitViewController!.showDetailViewController(safariController, sender: nil)
        }
    }
}

extension TopStoriesViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if !isLoadingData && indexPaths.contains { $0.row >= self.stories.count } {
            storyPageIndex += 1
            let newPagePromise = HackerNews.stories(forPage: storyPageIndex)
            pagePromise = all(pagePromise, newPagePromise).then { _, stories in
                self.newPageDidLoad(stories: stories)
            }
        }
    }
    
    private func newPageDidLoad(stories: [Story]) {
        var newRowIndices = Set<Int>()
        for story in stories {
            if !loadedStoryIDs.contains(story.id) {
                newRowIndices.insert(self.stories.count)
                self.stories.append(story)
                loadedStoryIDs.insert(story.id)
            }
        }
        DispatchQueue.main.async {
            if var indexPaths = self.tableView.indexPathsForVisibleRows {
                indexPaths = indexPaths.filter { newRowIndices.contains($0.row) }
                if indexPaths.count > 0 {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadRows(at: indexPaths, with: .none)
                    }
                }
            }
        }
    }
}
