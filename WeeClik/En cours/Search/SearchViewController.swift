//
//  SearchViewController.swift
//  WeeClik
//
//  Created by Herrick Wolber on 25/12/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import SDWebImage

// ERROR : Trouver bug sur l'espace créé en bas du table view

class SearchViewController: UITableViewController {
    var commerces = [Commerce]()
    var filteredComm = [Commerce]()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Nombre commrerce : \(commerces.count)")
        self.tableView.tableFooterView = UIView()
        setupSearchController()
    }
    
    func setupSearchController(){
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.barTintColor = UIColor(white: 0.9, alpha: 0.9)
        searchController.searchBar.placeholder = "Trouver un commerce"
        searchController.hidesNavigationBarDuringPresentation = false
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func filterRowsForSearchedText(_ searchText: String) {
        filteredComm = commerces.filter({ (commerce : Commerce) -> Bool in
            return commerce.nom.lowercased().contains(searchText.lowercased()) || commerce.descriptionO.lowercased().contains(searchText.lowercased()) || commerce.type.lowercased().contains(searchText.lowercased()) ||
                commerce.promotions.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    @IBAction func closeView(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

extension SearchViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterRowsForSearchedText(searchController.searchBar.text!)
    }
}

extension SearchViewController{
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredComm.count
        }
        return commerces.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UINib(nibName: "SearchCell", bundle: nil), forCellReuseIdentifier: "SearchCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchCell
        let comm : Commerce
        
        if isFiltering() {
            comm = filteredComm[indexPath.row]
        } else {
            comm = commerces[indexPath.row]
        }
        
        cell.nomCommerce.text = comm.nom
        
        if let imageThumbnailFile = comm.thumbnail {
            cell.coverImage.sd_setImage(with: URL(string: imageThumbnailFile.url!))
        } else {
            cell.coverImage.image = HelperAndKeys.getImageForTypeCommerce(typeCommerce: comm.type)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailCommerceViewController") as! DetailCommerceViewController
        if isFiltering() {
            detail.commerceObject = self.filteredComm[(tableView.indexPathForSelectedRow?.row)!]
        } else {
            detail.commerceObject = self.commerces[(tableView.indexPathForSelectedRow?.row)!]
        }
        
        self.navigationController?.pushViewController(detail, animated: true)
    }
}
