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
import Moya
import BrightFutures

struct WeatherData {

  struct WeatherStamp {
    let temp: Double
    let feelsLike: Double
    let weatherCondition: String
    let datetimeText: String
  }
  
  let location: String?
  let country: String?
  var weatherStamps: [WeatherStamp] = []
  var currentWeatherStamp: WeatherStamp? = nil
  
  /*
      Builds daily stamps by averaging
      data related to each day.
  */
  mutating func toDailyStamps() {
    
    func groupByDay(stamp: WeatherStamp) -> String {
      let datetimeText = stamp.datetimeText
      let spaceIndex = datetimeText.firstIndex(of: " ") ?? datetimeText.endIndex
      return String(datetimeText[..<spaceIndex])
    }
  
   
    let weatherStampsByDay = Dictionary(grouping: self.weatherStamps, by: groupByDay)
    print(weatherStampsByDay.keys)
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayDate = weatherStampsByDay.keys.filter( {$0 == formatter.string(from: Date()) } ).first

    var dailyStamps = [WeatherStamp]()
    
    for (day, stampsByDay) in weatherStampsByDay {
      let weatherConditions = stampsByDay.map { $0.weatherCondition }
      let mostFrequentCondition = Dictionary(grouping: weatherConditions, by: { $0 })
                                .mapValues({ $0.count })
                                .sorted(by: { $0.value > $1.value })
                                .first!.key
      
      let temps = stampsByDay.map { $0.temp }
      let averageTemp = temps.reduce(0, +) / Double(temps.count)
      
      let feelLikeValues = stampsByDay.map { $0.feelsLike }
      let averageFeelsLike = feelLikeValues.reduce(0, +) / Double(feelLikeValues.count)
      
      let weatherStamp = WeatherStamp(temp: averageTemp,
                                      feelsLike: averageFeelsLike,
                                      weatherCondition: mostFrequentCondition,
                                      datetimeText: day)
      
      if day == todayDate {
        self.currentWeatherStamp = weatherStamp
      } else {
        dailyStamps.append(weatherStamp)
      }
    }
    
    self.weatherStamps = dailyStamps
  }
}

extension WeatherData {
  
  /*
   
   JSON Structure.
   
   { city: { name: <String>, country: <String> },
     list: [ { main: { temp: <Double>, feels_like: <Double> },
               weather: { description: <String> },
               dt_txt: <String>
             },
             ...
           ]
   }
   
  */
  
  init(json: [String: Any]) {
    let cityDict = json["city"] as? [String: Any]
    self.location = cityDict?["name"] as? String
    self.country = cityDict?["country"] as? String
    
    if let jsonStampsList = json["list"] as? [Any] {
      for case let jsonStamp as [String: Any] in jsonStampsList {
        let mainDict = jsonStamp["main"] as? [String: Any]
        let weatherDict = (jsonStamp["weather"] as? [Any])?.first as? [String: Any]
        
        guard let temp = mainDict?["temp"] as? Double else { continue }
        guard let feelsLike = mainDict?["feels_like"] as? Double else { continue }
        guard let weatherCondition = weatherDict?["description"] as? String else { continue }
        guard let datetimeText = jsonStamp["dt_txt"] as? String else { continue }
        
        self.weatherStamps.append(WeatherStamp(temp: temp,
                                               feelsLike: feelsLike,
                                               weatherCondition: weatherCondition,
                                               datetimeText: datetimeText))
      }
    }
  }
  
  static func requestOpenWeather(_ coords: CLLocationCoordinate2D) -> Future<WeatherData, Never> {
    let provider = MoyaProvider<OpenWeatherService>()
    
    let promise = Promise<WeatherData, Never>()
    
    provider.request(.getForecastByGeoCoords(coords: coords)) { result in
      switch result {
      case let .success(moyaResponse):
        if moyaResponse.statusCode == 200 {
          let data = moyaResponse.data
          let jsonWithObjectRoot = try? JSONSerialization.jsonObject(with: data, options: [])
          if let json = jsonWithObjectRoot as? [String: Any] {
            var weatherData = WeatherData(json: json)
            weatherData.toDailyStamps()
            promise.success(weatherData)
          } else {
          }
        } else {
          print("BAD CODE \(moyaResponse.statusCode)")
          print(moyaResponse.data)
        }
      case let .failure(error):
        print(error)
      }
    }
    
    return promise.future
  }
}

class WeatherForecastViewController: UIViewController {
  var weatherData: WeatherData!
  
  @IBOutlet var tempLabel: UILabel!
  @IBOutlet var locationLabel: UILabel!
  @IBOutlet var feelsLikeLabel: UILabel!
  @IBOutlet var weatherConditionLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    print(weatherData)
    locationLabel.text = weatherData.location
    if let country = weatherData.country {
      locationLabel.text? += ", \(country)"
    }
    
    if let stamp = weatherData.currentWeatherStamp {
      tempLabel.text = "\(Int(stamp.temp.rounded()))°"
      feelsLikeLabel.text = "It feels like \(Int(stamp.feelsLike.rounded()))°"
      weatherConditionLabel.text = stamp.weatherCondition
    }
    
  }
}

class MapsViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
  @IBOutlet var labelLoading: UILabel!
  
  private let locationManager = CLLocationManager()
  private var mapView: GMSMapView!
  private var mapMarker: GMSMarker!
  
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
      mapView.delegate = self
      self.view = mapView
      
      mapMarker = GMSMarker(position: location)
      mapMarker.title = "You are here!"
      mapMarker.map = mapView
      
      labelLoading.removeFromSuperview()
    }
  }
  
  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
    mapMarker.position = coordinate
    
    let future = WeatherData.requestOpenWeather(coordinate)
    future.onSuccess { weatherData in
      self.performSegue(withIdentifier: "ForecastViewSegue", sender: weatherData)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "ForecastViewSegue") {
      let vc = segue.destination as! WeatherForecastViewController
      vc.weatherData = (sender as! WeatherData)
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("ERROR")
  }
  
  func locationManager(_ manager: CLLocationManager,
                       didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.requestLocation()
      mapView?.isMyLocationEnabled = true
    default: ()
    }
  }
}
