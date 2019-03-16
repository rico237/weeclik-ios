//
//  SharingToGroupsVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 11/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import Contacts
import SwiftMultiSelect

class SharingToGroupsVC: UIViewController {
    
    let contacts = [SwiftMultiSelectItem]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        AppDelegate.getContacts(completionHandler: { (granted, items) in
            if let items = items {
                for item in items {
                    print(item.string)
                }
            }
        })
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        
    }
 

}

extension SharingToGroupsVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath)
        return cell
    }
    
    
}
