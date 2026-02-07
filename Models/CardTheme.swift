//
//  CardTheme.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

enum CardTheme: String, CaseIterable, Identifiable, Codable {
    case pink
    case lime
    case sky
    case lavender
    case peach

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .pink: return Color(red: 1.0, green: 0.78, blue: 0.84)
        case .lime: return Color(red: 0.84, green: 0.92, blue: 0.62)
        case .sky: return Color(red: 0.72, green: 0.92, blue: 1.0)
        case .lavender: return Color(red: 0.82, green: 0.74, blue: 1.0)
        case .peach: return Color(red: 1.0, green: 0.86, blue: 0.66)
        }
    }
}

