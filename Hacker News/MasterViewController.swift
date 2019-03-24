//
//  MasterViewController.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row < stories.count {
            let story = stories[indexPath.row]
            let commentsLabel = "comment" + (story.descendants == 1 ? "" : "s")
            cell.textLabel!.text = story.title
            cell.detailTextLabel!.text = "\(story.descendants) \(commentsLabel)  \(story.domain)"
        } else {
            cell.textLabel!.text = ""
            cell.detailTextLabel!.text = ""
        }
        return cell
    }
}

extension MasterViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if !isLoadingData && indexPaths.contains { $0.row >= self.stories.count } {
            isLoadingData = true
            self.storyPageIndex += 1
            HackerNews.stories(forPage: storyPageIndex) { stories in
                self.isLoadingData = false
                if let stories = stories {
                    var newRowIndices = Set<Int>()
                    for story in stories {
                        if !self.loadedStoryIDs.contains(story.id) {
                            newRowIndices.insert(self.stories.count)
                            self.stories.append(story)
                            self.loadedStoryIDs.insert(story.id)
                        }
                    }
                    DispatchQueue.main.async {
                        if var visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
                            visibleIndexPaths = visibleIndexPaths.filter( { newRowIndices.contains($0.row) } )
                            if visibleIndexPaths.count > 0 {
                                self.tableView.reloadRows(at: visibleIndexPaths, with: .none)
                            }
                        }
                    }
                }
            }
        }
    }
}
