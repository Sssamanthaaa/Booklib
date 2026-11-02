import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context

    init() {
        // Dark navy tab bar with a lime selected tab, matching the web app.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.navyDeep)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "house") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
        }
        .tint(Theme.lime)
        .onAppear { Seed.runIfNeeded(context) }
    }
}
