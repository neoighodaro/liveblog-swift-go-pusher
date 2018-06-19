//
//  PostsTableViewController.swift
//  LiveBlog
//
//  Created by Neo Ighodaro on 19/06/2018.
//  Copyright © 2018 TapSharp Interactive. All rights reserved.
//

import UIKit
import Alamofire
import PusherSwift
import NotificationBannerSwift

struct Post: Codable {
    let id: Int64
    let content: String
}

struct Posts: Codable {
    var items: [Post]
}

class PostsTableViewController: UITableViewController {
    
    var posts = Posts(items: [])
    var pusher: Pusher!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pusher = Pusher(key: "PUSHER_APP_KEY", options: PusherClientOptions(host: .cluster("PUSHER_APP_CLUSTER")))
        
        let channel = pusher.subscribe("live-blog-stream")
        
        let _ = channel.bind(eventName: "new-post") { data in
            if let data = data as? [String: AnyObject] {
                if let id = data["id"] as? Int64, let content = data["content"] as? String {
                    self.posts.items.insert(Post(id: id, content: content), at: 0)
                    self.tableView.reloadData()
                }
            }
        }
        
        pusher.connect()
        
        Alamofire.request("http://127.0.0.1:9000/posts").validate().responseJSON { resp in
            guard resp.result.isSuccess, let data = resp.data else {
                return StatusBarNotificationBanner(title: "Unable to fetch posts", style: .danger).show()
            }
            
            if let posts = try? JSONDecoder().decode(Posts.self, from: data) {
                self.posts = posts
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "post", for: indexPath)
        let post = self.posts.items[indexPath.row]

        cell.textLabel?.text = post.content

        return cell
    }

}
