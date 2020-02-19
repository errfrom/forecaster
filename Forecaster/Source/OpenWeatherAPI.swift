//
//  OpenWeatherAPI.swift
//  Forecaster
//
//  Created by Dmitri Schuiski on 2/19/20.
//  Copyright © 2020 Dmitri Schuiski. All rights reserved.
//

import Foundation
import CoreLocation
import Moya

public enum OpenWeatherService {
  static private let apiKey = "320fa6009c6a614d916b67b94ed7d85d"
  case getForecastByGeoCoords (coords:  CLLocationCoordinate2D)
}

extension OpenWeatherService: TargetType {
  public var baseURL: URL {
    return URL(string: "https://api.openweathermap.org")!
  }
  
  public var path: String {
    switch self {
    case .getForecastByGeoCoords:
      return "/data/2.5/forecast"
    }
  }
  
  public var method: Moya.Method {
    switch self {
    case .getForecastByGeoCoords:
      return .get
    }
  }
  
  public var task: Task {
    switch self {
    case .getForecastByGeoCoords(let coords):
      let parameters = ["lat":   String(coords.latitude),
                        "lon":   String(coords.longitude),
                        "units": "metric",
                        "appid": OpenWeatherService.apiKey]
      return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
  }
  
  public var sampleData: Data {
    return Data()
  }
  
  public var headers: [String : String]? {
    return ["Content-Type": "application/json"]
  }
}
