//
//  CallTableViewController.swift
//  WChat
//
//  Created by David Kababyan on 21/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD
import UserNotifications
import FirebaseFirestore

class CallTableViewController: UITableViewController, UISearchResultsUpdating {

    var allCalls: [CallN] = []
    var filteredCalls: [CallN] = []

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    let searchController = UISearchController(searchResultsController: nil)
    var callListener: ListenerRegistration!

    override func viewWillAppear(_ animated: Bool) {
        loadCalls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        callListener.remove()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setBadges(controller: self.tabBarController!)

        //to remove empty cell lines
        tableView.tableFooterView = UIView()

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true

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
        
        var call: CallN!
        
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
        
        var call: CallN!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            call = filteredCalls[indexPath.row]
        } else {
            call = allCalls[indexPath.row]
        }

        call.saveCallInBackground()
        
        //call user again
        let newCall = call!
        
        newCall.objectId = UUID().uuidString
        newCall.callDate = Date()

        newCall.saveCallInBackground()
        callUser(withId: call.withUserId, withName: call.withUserFullName)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {

            var tempCall: CallN!
            
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
        
        callListener = reference(collectionReference: .Call).document(FUser.currentId()).collection(FUser.currentId()).order(by: kDATE, descending: true).limit(to: 20).addSnapshotListener({ (snapshot, error) in
            
            self.allCalls = []

            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                
                let sortedDictionary = dictionaryFromSnapshots(snapshots: snapshot.documents)
                
                for callDictionary in sortedDictionary {

                    let call = CallN(_dictionary: callDictionary)
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
    
    //MARK: CallUser
    
    func callUser(withId: String, withName: String) {

        let call = callClient().callUser(withId: withId, headers: [kFULLNAME : withName])
        
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
        
        callVC._call = call
        
        self.present(callVC, animated: true, completion: nil)
        
    }

    func callClient() -> SINCallClient {
        return appDelegate._client.call()
    }


}
