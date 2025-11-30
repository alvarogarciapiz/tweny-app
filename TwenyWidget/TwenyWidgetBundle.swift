//
//  TwenyWidgetBundle.swift
//  TwenyWidget
//
//  Created by Álvaro García Pizarro on 29/11/25.
//

import WidgetKit
import SwiftUI

@main
struct TwenyWidgetBundle: WidgetBundle {
    var body: some Widget {
        TwenyWidget()
        TwenyWidgetLiveActivity()
    }
}
