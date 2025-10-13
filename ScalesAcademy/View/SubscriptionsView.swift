import SwiftUI
import StoreKit

struct SubscriptionsView: View {
    @ObservedObject private var licenceManager = LicenceManager.shared
    @State private var isLoading = true
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    func willAutoRenew() -> Bool {
        if let autoRenew = licenceManager.willAutoRenew {
            return autoRenew
        }
        return true
    }
    
    func getRenewDateTime(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        let dateTimeString = formatter.string(from: date)
        return dateTimeString // e.g., "2025-10-01 14:23:45"
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading && licenceManager.products.isEmpty {
                    ProgressView("Loading subscriptions…")
                } else if licenceManager.products.isEmpty {
                    VStack(spacing: 12) {
                        Text("No subscriptions found")
                            .font(.headline)
                        Button("Retry") {
                            Task {
                                isLoading = true
                                await licenceManager.refreshProducts()
                                await licenceManager.refreshEntitlementsAndStatus()
                                isLoading = false
                            }
                        }
                    }
                } else {
                    VStack {
                        if licenceManager.licenceType != .subscribed {
                            Text(TrialLicenceManager.shared.getStatus())
                        }
                        List {
                            if licenceManager.licenceType == .subscribed {
                                Section {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                        VStack(alignment: .leading) {
                                            Text("Subscription Active").font(.headline)
                                            if self.willAutoRenew() {
                                                if let exp = licenceManager.lastExpirationDate {
                                                    Text("Renews on \(self.getRenewDateTime(exp))")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            else {
                                                Text("No automatic renewal")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            
                            ///▶️ Note that when a subscription is cancelled it it not deleted. It is set to no auto-renew and will disappear at the
                            ///start of the next subscription period. So when a user deletes a subscription via "manage" then they are only told it
                            ///wont renew.
                            // Products
                            Section("Subscriptions") {
                                ForEach(licenceManager.products, id: \.id) { product in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.displayName)
                                                .font(.headline)
                                            Text(product.displayPrice)
                                        }
                                        Spacer()
                                        FigmaButton(licenceManager.licenceType == .subscribed ? "Manage" : "Purchase", action: {
                                            Task {
                                                await licenceManager.purchase(product)
                                                try? await AppStore.sync()
                                                await licenceManager.refreshEntitlementsAndStatus()
                                            }
                                        })
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        Task { await licenceManager.purchase(product) }
                                    }
                                }
//                                    FigmaButton("TEST", action: {
//                                        Task {
//                                            //try? await AppStore.sync()         // prompts StoreKit to resync entitlements
//                                            //await licenceManager.refreshEntitlementsAndStatus()
//                                            Task { await licenceManager.refreshEntitlementsAndStatus() }
//                                        }
//                                    })
                            }
                            
                            // Restore
//                            Section {
//                                Button("Restore Purchases") {
//                                    Task { await licenceManager.restorePurchases() }
//                                }
//                            }
                        }
                        .listStyle(.insetGrouped)
                        if !self.compact {
                            VStack() {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .imageScale(.medium)
                                        .foregroundColor(.green)
                                        .padding(.top, 1)
                                    let info = "Purchasing a subscription provides you with access to all the Scales Academy content. The subscription types are listed above."
                                    Text(info).padding()
                                }
                            }
                        }
                        
                        HStack {
                            if !self.compact {
                                Text("If you’ve previously subscribed with this Apple ID, tap Restore to regain access.").foregroundColor(.secondary)
                            }
                            Button {
                                Task { await licenceManager.restorePurchases() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                    Text("Restore Purchases")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            //.controlSize(.large)
                        }
                        Text("")
                        HStack {
                            Text("By subscribing, you agree to:")
                                .font(.footnote)
                            Link("Terms of Use (EULA)",
                                 destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .font(.footnote)
                            Link("  Privacy Policy",
                                 destination: URL(string: "https://www.musicmastereducation.co.nz/ScalesAcademy/privacy-policy.html")!)
                                .font(.footnote)
                        }
//                        HStack {
//                            if let statusMsg = self.licenceManager.statusMessage1 {
//                                Text("status: \(statusMsg)")
//                            }
//                        }

                    }
                    .padding()
                    .figmaRoundedBackgroundWithBorder()
                    .frame(width: UIScreen.main.bounds.width * (compact ? 0.6 : 0.4),
                            height: UIScreen.main.bounds.height * (compact ? 0.7 : 0.6))
                }
            }
            
            .navigationTitle("Subscriptions")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .commonToolbar(
                title: "Subscriptions", helpMsg: "Use this screen to mange your Scales Academy subscriptions", onBack: {}
            )
        }

        .task {
            // Initial load
            if !Parameters.shared.inDevelopmentMode {
                await licenceManager.refreshProducts()
                await licenceManager.refreshEntitlementsAndStatus()
                isLoading = false
            }
        }
    }

}

// Handy label for period (month/year) from StoreKit 2 Product
private extension Product {
    var subscriptionPeriodLabel: String {
        guard let info = subscription?.subscriptionPeriod else { return "Auto-renewing" }
        switch (info.unit, info.value) {
        case (.day, 1): return "Daily"
        case (.day, let v): return "Every \(v) days"
        case (.week, 1): return "Weekly"
        case (.week, let v): return "Every \(v) weeks"
        case (.month, 1): return "Monthly"
        case (.month, let v): return "Every \(v) months"
        case (.year, 1): return "Yearly"
        case (.year, let v): return "Every \(v) years"
        @unknown default:  return "Auto-renewing"
        }
    }
}
