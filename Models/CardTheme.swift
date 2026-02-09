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
        case .pink: return .softRose
        case .lime: return .freshLime
        case .sky: return .skyBlue
        case .lavender: return .lavenderPurple
        case .peach: return .softTerracotta
        }
    }
}

