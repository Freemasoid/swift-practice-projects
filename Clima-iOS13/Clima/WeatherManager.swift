//
//  WeatherManager.swift
//  Clima
//
//  Created by Roman on 29.01.2025.
//  Copyright © 2025 App Brewery. All rights reserved.
//

import CoreLocation
import Foundation

protocol WeatherManagerDelegate {
    func didUpdateWeather(
        _ weatherManager: WeatherManager, weather: WeatherModel)
    func didFailWithError(error: Error)
}

struct WeatherManager {
    let weatherURL =
        "https://api.weatherapi.com/v1/current.json?key=\(ProcessInfo.processInfo.environment["WEATHER_API_KEY"]!)"

    var delegate: WeatherManagerDelegate?

    func fetchWeather(cityName: String) {
        let urlString = "\(weatherURL)&q=\(cityName)"
        self.performRequest(urlString: urlString)
    }

    func fetchWeather(
        latitude: CLLocationDegrees, longtitude: CLLocationDegrees
    ) {
        let urlString = "\(weatherURL)&q=\(latitude),\(longtitude)"
        self.performRequest(urlString: urlString)
    }

    func performRequest(urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }

                if let safeData = data {
                    if let weather = self.parseJSON(weatherData: safeData) {
                        self.delegate?.didUpdateWeather(self, weather: weather)
                    }
                }
            }
            task.resume()
        }
    }

    func parseJSON(weatherData: Data) -> WeatherModel? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(
                WeatherData.self, from: weatherData)
            let conditionText = decodedData.current.condition.text
            let conditionIcon = decodedData.current.condition.icon
            let temp = decodedData.current.temp_c
            let cityName = decodedData.location.name

            let weather = WeatherModel(
                conditionText: conditionText, conditionIcon: conditionIcon,
                cityName: cityName, temperature: temp)
            return weather
        } catch {
            delegate?.didFailWithError(error: error)
            return nil
        }

    }

}
