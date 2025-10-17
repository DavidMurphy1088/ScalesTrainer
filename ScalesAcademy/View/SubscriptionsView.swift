import SwiftUI
import StoreKit

struct SubscriptionsView: View {
    @ObservedObject private var licenceManager = LicenceManager.shared
    @State private var isLoading = true
    let compact = UIDevice.current.userInterfaceIdiom == .phone

    // MARK: - Helpers
    private func renewDateString(_ date: Date) -> String {
        date.formatted(.dateTime
            .year().month().day()
            .hour().minute())
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
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        // Trial messaging when not subscribed
                        if licenceManager.licenceType != .subscribed {
                            Text(TrialLicenceManager.shared.getStatus())
                                .font(.subheadline)
                                //.foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        List {
                            // Active status block
                            if licenceManager.licenceType == .subscribed {
                                Section {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Subscription Active")
                                                .font(.headline)

                                            if let exp = licenceManager.lastExpirationDate {
                                                if (licenceManager.willAutoRenew ?? false) {
                                                    Text("Renews on \(renewDateString(exp))")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                } else {
                                                    Text("Active until \(renewDateString(exp)) — will not auto-renew")
                                                        .font(.subheadline)
                                                        .foregroundColor(.orange)
                                                        .bold(true)
                                                }
                                            }

                                            if licenceManager.isInBillingRetry {
                                                Text("There’s a billing issue — Apple will retry. You still have access for now.")
                                                    .font(.footnote)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }

                            // Products section
                            Section("Subscriptions") {
                                ForEach(licenceManager.products, id: \.id) { product in
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.displayName)
                                                .font(.headline)
                                            HStack(spacing: 8) {
                                                Text(product.displayPrice)
                                                Text("• \(product.subscriptionPeriodLabel)")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .font(.subheadline)
                                        }
                                        Spacer()

                                        // When already subscribed, we guide to Manage instead of starting a purchase
                                        if licenceManager.licenceType == .subscribed {
                                            Button("Manage") {
                                                Task { await licenceManager.showManageSubscriptions() }
                                            }
                                            .buttonStyle(.bordered)
                                        } else {
                                            Button("Subscribe") {
                                                Task {
                                                    await licenceManager.purchase(product)
                                                    // No extra sync here; LicenceManager handles refresh after purchase.
                                                }
                                            }
                                            .buttonStyle(.borderedProminent)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    // Avoid extra onTap purchase to prevent accidental double triggers
                                }
                            }
                        }
                        .listStyle(.insetGrouped)

                        // Info block (iPad/large screens)
                        if !compact {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.medium)
                                    .foregroundColor(.green)
                                    .padding(.top, 2)
                                Text("A subscription unlocks all Scales Academy content. You can manage or cancel any time in your Apple subscription settings.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Restore + Manage
                        HStack(spacing: 12) {
                            Button {
                                Task { await licenceManager.restorePurchases() }
                            } label: {
                                Label("Restore Purchases", systemImage: "arrow.clockwise.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                Task { await licenceManager.showManageSubscriptions() }
                            } label: {
                                Label("Manage Subscription", systemImage: "creditcard.and.123")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        // Legal links
                        HStack(spacing: 6) {
                            Text("By subscribing, you agree to:")
                                .font(.footnote)
                            Link("Terms of Use (EULA)",
                                 destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .font(.footnote)
                            Text("•").font(.footnote)
                            Link("Privacy Policy",
                                 destination: URL(string: "https://www.musicmastereducation.co.nz/ScalesAcademy/privacy-policy.html")!)
                                .font(.footnote)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .figmaRoundedBackgroundWithBorder()
                    .frame(
                        width: UIScreen.main.bounds.width * (compact ? 0.6 : 0.4),
                        height: UIScreen.main.bounds.height * (compact ? 0.7 : 0.6)
                    )
                }
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .commonToolbar(
                title: "Subscriptions",
                helpMsg: "Use this screen to manage your Scales Academy subscriptions",
                onBack: {}
            )
        }
        .task {
            // Initial load
            if !Parameters.shared.inDevelopmentMode {
                await licenceManager.refreshProducts()
                await licenceManager.refreshEntitlementsAndStatus()
                isLoading = false
            } else {
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
        case (.day, 1):   return "Daily"
        case (.day, let v):   return "Every \(v) days"
        case (.week, 1):  return "Weekly"
        case (.week, let v):  return "Every \(v) weeks"
        case (.month, 1): return "Monthly"
        case (.month, let v): return "Every \(v) months"
        case (.year, 1):  return "Yearly"
        case (.year, let v):  return "Every \(v) years"
        @unknown default:  return "Auto-renewing"
        }
    }
}

