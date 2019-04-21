//
//  MasterViewController.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import UIKit

class TopStoriesViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var stories = [Story]()
    var loadedStoryIDs = Set<UInt>()
    var storyPageIndex: UInt = 1
    var isLoadingData = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(userDidRequestRefresh(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
        
        self.refreshStories()
        
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
        HackerNews.stories(forPage: 1) { stories in
            self.isLoadingData = false
            
            if let stories = stories {
                self.storyPageIndex = 1
                self.stories.removeAll()
                self.stories.append(contentsOf: stories)
            }
            
            DispatchQueue.main.async {
                self.refreshControl!.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Segues

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                if indexPath.row >= stories.count {
                    tableView.deselectRow(at: indexPath, animated: true)
                    return false
                }
            }
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let story = stories[indexPath.row] as Story
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = story
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
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
}

extension TopStoriesViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if !isLoadingData && indexPaths.contains { $0.row >= self.stories.count } {
            isLoadingData = true
            storyPageIndex += 1
            let newStoriesStartIndex = self.stories.count
            HackerNews.stories(forPage: storyPageIndex) { stories in
                self.isLoadingData = false
                if let stories = stories {
                    self.newPageDidLoad(stories: stories, atIndex: newStoriesStartIndex)
                }
            }
        }
    }
    
    private func newPageDidLoad(stories: [Story], atIndex: Int) {
        var newRowIndices = Set<Int>()
        var currentIndex = atIndex
        for story in stories {
            if !loadedStoryIDs.contains(story.id) {
                newRowIndices.insert(currentIndex)
                self.stories.insert(story, at: currentIndex)
                currentIndex += 1
                loadedStoryIDs.insert(story.id)
            }
        }
        DispatchQueue.main.async {
            if var indexPaths = self.tableView.indexPathsForVisibleRows {
                indexPaths = indexPaths.filter { newRowIndices.contains($0.row) }
                if indexPaths.count > 0 {
                    self.tableView.reloadRows(at: indexPaths, with: .none)
                }
            }
        }
    }
}
