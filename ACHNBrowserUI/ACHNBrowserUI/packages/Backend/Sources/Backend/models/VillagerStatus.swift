//
//  File.swift
//  
//
//  Created by Thomas Ricouard on 23/05/2020.
//

import Foundation
import SwiftUI

public enum VillagerStatus: String, CaseIterable, Codable {
    case unknown, hate, movedIn, movedOut
    
    public func labelValue() -> String {
        switch self {
        case .unknown:
            return "❓"
        case .hate:
            return "🤮"
        case .movedIn:
            return "🏠"
        case .movedOut:
            return "🛫"
        }
    }
    
    public func sectionLabelValue() -> LocalizedStringKey {
        switch self {
        case .unknown:
            return LocalizedStringKey("❓Unknown")
        case .hate:
            return LocalizedStringKey("🤮 Hate")
        case .movedIn:
            return LocalizedStringKey("🏠 Resident")
        case .movedOut:
            return LocalizedStringKey("🛫 Moved out")
        }
    }
}

