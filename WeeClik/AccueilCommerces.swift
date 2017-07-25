//
//  AccueilCommerces.swift
//  WeeClik
//
//  Created by Herrick Wolber on 21/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import DropDownMenuKit
import Parse

class AccueilCommerces: UIViewController, DropDownMenuDelegate {

    var titleView        : DropDownTitleView!
    var toutesCategories : Array<String>!
    var categoriesCells  : Array<DropDownMenuCell> = []
    var commerces        : Array<Commerce> = []
    var queryObjects     : Array<PFObject> = []
    
    @IBOutlet var navigationBarMenu: DropDownMenu!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "ACCUEIL"
        
        toutesCategories = ["Restaurants", "Plomberie"]
        
        let title = prepareNavigationBarMenuTitleView()
        
        prepareNavigationBarMenu(title)
        updateMenuContentOffsets()
        queryObjectsFromDB(typeCategorie: "Restaurants")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationBarMenu.container = view
    }
    
    func queryObjectsFromDB(typeCategorie : String){
        let query = PFQuery(className: "Commerce")
        query.whereKey("typeCommerce", equalTo: typeCategorie)
        query.findObjectsInBackground { (objects : [PFObject]?, error : Error?) in
            if error == nil {
                if let arr = objects{
                    print("Number of items in BD : \(arr.count)")
                    self.queryObjects = arr
                }
            } else {
                HelperAndKeys.showAlertWithMessage(theMessage: (error?.localizedDescription)!, title: "Erreur", viewController: self)
            }
        }
    }
    
    func prepareNavigationBarMenuTitleView() -> String {
        titleView = DropDownTitleView()
        titleView.addTarget(self,
                            action: #selector(AccueilCommerces.willToggleNavigationBarMenu(_:)),
                            for: .touchUpInside)
        titleView.addTarget(self,
                            action: #selector(AccueilCommerces.didToggleNavigationBarMenu(_:)),
                            for: .valueChanged)
        titleView.titleLabel.textColor = UIColor.white
        
        navigationItem.titleView = titleView
        
        return titleView.title!
    }
    
    func prepareNavigationBarMenu(_ currentChoice: String) {
        navigationBarMenu = DropDownMenu(frame: view.bounds)
        navigationBarMenu.delegate = self
        
        for string in toutesCategories  {
            
            let cell = DropDownMenuCell()
            cell.textLabel!.text = string
            cell.menuAction = #selector(AccueilCommerces.choose(_:))
            cell.menuTarget = self
            if currentChoice == cell.textLabel!.text {
                cell.accessoryType = .checkmark
            }
            
            categoriesCells.append(cell)
        }
        
        navigationBarMenu.menuCells = categoriesCells
        navigationBarMenu.selectMenuCell(categoriesCells.first!)
        
        // If we set the container to the controller view, the value must be set
        // on the hidden content offset (not the visible one)
        updateMenuContentOffsets()
        
        // For a simple gray overlay in background
        navigationBarMenu.backgroundView = UIView(frame: navigationBarMenu.bounds)
        navigationBarMenu.backgroundView!.backgroundColor = UIColor.black
        navigationBarMenu.backgroundAlpha = 0.7
    }
    
    func updateMenuContentOffsets() {
//        navigationBarMenu.visibleContentOffset = navigationController!.navigationBar.frame.size.height + statusBarHeight()
        navigationBarMenu.visibleContentOffset = 0
    }
    
    @IBAction func showToolbarMenu() {
        if titleView.isUp {
            titleView.toggleMenu()
        }
    }
    
    @IBAction func willToggleNavigationBarMenu(_ sender: DropDownTitleView) {
        
        if sender.isUp {
            navigationBarMenu.hide()
        }
        else {
            navigationBarMenu.show()
        }
    }
    
    @IBAction func didToggleNavigationBarMenu(_ sender: DropDownTitleView) {
//        print("Sent did toggle navigation bar menu action")
    }
    
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {
        if menu == navigationBarMenu {
            titleView.toggleMenu()
        }
        else {
            menu.hide()
        }
    }
    
    @IBAction func choose(_ sender: AnyObject) {
        titleView.title = (sender as! DropDownMenuCell).textLabel!.text
        navigationItem.titleView = titleView
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            // If we put this only in -viewDidLayoutSubviews, menu animation is
            // messed up when selecting an item
            self.updateMenuContentOffsets()
            
        }, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return min(statusBarSize.width, statusBarSize.height)
    }
}
