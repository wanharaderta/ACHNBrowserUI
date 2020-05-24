//
//  File.swift
//  
//
//  Created by Thomas Ricouard on 24/05/2020.
//

import Foundation
import SwiftUI

public struct HourlyMusic: Codable, Identifiable {
    public let id: Int
    public let hour: Int
    public let weather: String
    
    public var localizedName: LocalizedStringKey {
        LocalizedStringKey("\(hour)h when \(weather.lowercased())")
    }
}
