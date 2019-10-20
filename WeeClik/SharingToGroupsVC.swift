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
    override func viewDidLoad() {super.viewDidLoad()}
}

extension SharingToGroupsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return contacts.count}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath)
    }
}
