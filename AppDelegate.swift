//
//  AppDelegate.swift
//  VrtualTourist
//
//  Created by Segnonna Hounsou on 12/04/2022.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        dataController.load()
        
        let navigationController = window?.rootViewController as! UINavigationController
        let notebooksListViewController = navigationController.topViewController as! TravelLocationsMapViewController
        notebooksListViewController.dataController = dataController
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }

    func saveViewContext() {
        try? dataController.viewContex.save()
    }

}

