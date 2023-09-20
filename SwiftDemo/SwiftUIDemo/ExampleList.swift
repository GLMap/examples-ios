//
//  ExampleList.swift
//  SwiftUIDemo
//
//  Created by Evgen Bodunov on 26.04.23.
//  Copyright © 2023 Evgen Bodunov. All rights reserved.
//

import SwiftUI

enum Example: String, CaseIterable, Identifiable {
    case moveMap = "Move map and handle tap"
    case displayMarkers = "Display markers"
    case displayGeoJSON = "Display GeoJSON"

    var id: String { rawValue }
}

struct ExampleList: View {
    var body: some View {
        NavigationView {
            List(Example.allCases) { example in
                #if os(macOS)
                    NavigationLink(destination: destinationView(for: example)
                        .navigationTitle(example.rawValue))
                    {
                        Text(example.rawValue)
                    }
                #else
                    NavigationLink(destination: destinationView(for: example)
                        .navigationTitle(example.rawValue)
                        .navigationBarTitleDisplayMode(.inline))
                    {
                        Text(example.rawValue)
                    }
                #endif
            }
            .navigationTitle("Examples")
        }
    }

    @ViewBuilder
    private func destinationView(for example: Example) -> some View {
        switch example {
        case .moveMap:
            MoveMapExampleView()
        default:
            Text("TODO")
        }
    }
}

struct ExampleList_Previews: PreviewProvider {
    static var previews: some View {
        ExampleList()
    }
}
