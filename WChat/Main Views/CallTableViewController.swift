//
//  CallTableViewController.swift
//  WChat
//
//  Created by David Kababyan on 21/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD

class CallTableViewController: UITableViewController, UISearchResultsUpdating {

    var allCalls: [Call] = []
    var filteredCalls: [Call] = []

    let searchController = UISearchController(searchResultsController: nil)

    
    override func viewDidLoad() {
        super.viewDidLoad()

        //to remove empty cell lines
        tableView.tableFooterView = UIView()

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true

        loadCalls()
    }


    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCalls.count
        } else {
            return allCalls.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CallTableViewCell
        
        var call: Call!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            call = filteredCalls[indexPath.row]
        } else {
            call = allCalls[indexPath.row]
        }

        cell.generateCellWith(call: call)

        return cell
    }

    //MARK: TableviewDelegates
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var call: Call!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            call = filteredCalls[indexPath.row]
        } else {
            call = allCalls[indexPath.row]
        }

        call.saveCallInBackground()
        //call user again
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {

            var tempCall: Call!
            
            if searchController.isActive && searchController.searchBar.text != "" {
                tempCall = filteredCalls[indexPath.row]
                filteredCalls.remove(at: indexPath.row)
            } else {
                tempCall = allCalls[indexPath.row]
                allCalls.remove(at: indexPath.row)
            }
            
            tempCall.deleteCall()
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    
    //MARK: LoadCalls
    
    func loadCalls() {
        
        firebase.child(kCALL_PATH).child(FUser.currentId()).observe(.value, with: {
            snapshot in
            
            self.allCalls = []

            if snapshot.exists() {
                
                let allCallDictionaries = ((snapshot.value as! NSDictionary).allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)])
                
                
                for callDictionary in allCallDictionaries {
                    
                    let call = Call(_dictionary: callDictionary as! NSDictionary)
                    self.allCalls.append(call)
                }
                
            }
            
            
            self.tableView.reloadData()
        })
    }

    //MARK: search controler functions
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredCalls = allCalls.filter({ (call) -> Bool in
            
            var callerName: String!
            //check whos name we should search
            if call.callerId == FUser.currentId() {
                callerName = call.withUserFullName
            } else {
                callerName = call.callerFullName
            }
            
            return (callerName).lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }

}
