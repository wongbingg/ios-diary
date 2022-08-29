//
//  WeatherModel.swift
//  Diary
//
//  Created by 이원빈 on 2022/08/29.
//

import Foundation

struct WeatherModel: Codable {
    let weather: [Weather]
    struct Weather: Codable {
        let main: String
        let icon: String
    }
    let sys: Sys
    struct Sys: Codable {
        let country: String
    }
    let name: String
}
