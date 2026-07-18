//
//  AwwadQuickLogIntent.swift
//  Runner
//
//  iOS 17 interactive-widget intent: the widget's quick-log button runs the
//  SAME Dart background callback as Android (homeWidgetBackgroundCallback in
//  lib/core/widget/widget_sync.dart) via home_widget's background worker.
//  IMPORTANT (Xcode step, see docs/IOS_PARITY_SETUP.md): this file must have
//  TARGET MEMBERSHIP in BOTH Runner and the AwwadWidget extension.
//

import AppIntents
import Foundation
import home_widget

@available(iOS 17, *)
public struct AwwadQuickLogIntent: AppIntent {
  static public var title: LocalizedStringResource = "Awwad Quick Log"

  @Parameter(title: "Widget URI")
  var url: URL?

  @Parameter(title: "AppGroup")
  var appGroup: String?

  public init() {}

  public init(url: URL?, appGroup: String?) {
    self.url = url
    self.appGroup = appGroup
  }

  public func perform() async throws -> some IntentResult {
    await HomeWidgetBackgroundWorker.run(url: url, appGroup: appGroup!)
    return .result()
  }
}

/// Keeps the button working even when the app process is fully suspended.
@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension AwwadQuickLogIntent: ForegroundContinuableIntent {}
