//
//  AwwadWidgetBundle.swift
//  AwwadWidget
//
//  Widget-extension entry point. This file (with AwwadWidget.swift) becomes
//  the «AwwadWidget» WidgetKit extension target - see docs/IOS_PARITY_SETUP.md
//  for the one-time Xcode wiring (target + app group group.com.awwad.awwad).
//

import SwiftUI
import WidgetKit

@main
struct AwwadWidgetBundle: WidgetBundle {
  var body: some Widget {
    AwwadWidget()
  }
}
