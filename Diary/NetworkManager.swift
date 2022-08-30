//
//  NetworkManager.swift
//  Diary
//
//  Created by unchain, 웡빙 on 2022/08/30.
//

import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    func requestWeatherData(latitude: String?, longitude: String?, _ completion: @escaping (WeatherModel) -> Void) {
        guard let latitude = latitude, let longitude = longitude else {
            return
        }
        var urlComponents = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather?")
        let lat = URLQueryItem(name: "lat", value: latitude)
        let lon = URLQueryItem(name: "lon", value: longitude)
        let apiKey = URLQueryItem(name: "appId", value: "82dc71828b844e5d194f3128d649c0e8")
        urlComponents?.queryItems?.append(lat)
        urlComponents?.queryItems?.append(lon)
        urlComponents?.queryItems?.append(apiKey)
        guard let url = urlComponents?.url else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { return }
            let successRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  successRange.contains(statusCode) else {
                return
            }
            guard let resultData = data,
                  let fetchedData = JsonParser.fetch(resultData) else {
                return
            }
            completion(fetchedData)
        }
        dataTask.resume()
    }
}
