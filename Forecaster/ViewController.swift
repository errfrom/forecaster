//
//  ViewController.swift
//  Forecaster
//
//  Created by Dmitri Schuiski on 2/17/20.
//  Copyright © 2020 Dmitri Schuiski. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps

class ViewController: UIViewController, CLLocationManagerDelegate {
  @IBOutlet var labelLoading: UILabel!
  
  private let locationManager = CLLocationManager()
  private var mapView: GMSMapView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    GMSServices.provideAPIKey("AIzaSyCbEhvLvmmosZDHWC3tJQx-6zUEtQhGOKQ")
    
    locationManager.requestWhenInUseAuthorization()
    locationManager.delegate = self
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let location = locationManager.location?.coordinate
    if let location = location {
      let camera = GMSCameraPosition.camera(withTarget: location, zoom: 15)
      mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
      labelLoading.removeFromSuperview()
      self.view.addSubview(mapView)
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("ERROR")
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.requestLocation()
      mapView?.isMyLocationEnabled = true
    default: ()
    }
  }
}
