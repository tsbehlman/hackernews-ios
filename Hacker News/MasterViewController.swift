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
        HackerNews.stories(forPage: 1) { stories in
            DispatchQueue.main.async {
                if let stories = stories {
                    self.stories.removeAll()
                    self.stories.append(contentsOf: stories)
                    self.tableView.reloadData()
                }
                
                self.refreshControl!.endRefreshing()
            }
        }
    }

    // MARK: - Segues

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
        return stories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let story = stories[indexPath.row]
        let commentsLabel = "comment" + (story.descendants == 1 ? "" : "s")
        cell.textLabel!.text = story.title
        cell.detailTextLabel!.text = "\(story.descendants) \(commentsLabel)  \(story.domain)"
        return cell
    }
}

