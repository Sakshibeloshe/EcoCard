//
//  FolderModel.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct FolderModel: Identifiable, Hashable {
    let id: UUID
    var name: String
    var color: Color = .skyBlue
}

