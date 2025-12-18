//
//  ShopView.swift
//  URFocus
//
//  Created by Lior Zendel on 11/18/25.
//


import SwiftUI

struct ShopView: View {
    @AppStorage("coins") private var coins: Int = 1000
    @AppStorage("useMidnightBlueTheme") private var useMidnightBlueTheme: Bool = false
    @AppStorage("useGradientTheme") private var useGradientTheme: Bool = false
    @AppStorage("selectedBackground") private var selectedBackground: String = "system"
    @State private var showInsufficientFundsAlert = false

    struct ShopItem: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let cost: Int
    }

    private let items: [ShopItem] = [
        .init(
            name: "Focus Theme: Midnight Blue",
            description: "A deep, calming color theme for late-night grinds.",
            cost: 1
        ),
        .init(
            name: "Sticker Pack: Study Gremlins",
            description: "Silly little critters to cheer you on in the UI.",
            cost: 1
        ),
        .init(
            name: "Title: Library Goblin",
            description: "Show off your streak with a goofy profile title.",
            cost: 1
        ),
        .init(
            name: "Background: Yellow–Blue Gradient",
            description: "A vibrant diagonal gradient from UR yellow to UR blue.",
            cost: 1
        )
    ]

    var body: some View {
        List {
            // Balance section
            Section(header: Text("Your Balance")) {
                HStack {
                    Label("Coins: \(coins)", systemImage: "creditcard.circle.fill")
                        .font(.headline)
                }
            }

            // Shop items
            Section(header: Text("UR Focus Shop")) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        // Determine if this item is already owned (for now, just the Midnight Blue theme)
                        let isOwned: Bool = {
                            if item.name == "Focus Theme: Midnight Blue" { return useMidnightBlueTheme }
                            if item.name == "Background: Yellow–Blue Gradient" { return useGradientTheme }
                            return false
                        }()

                        let isBackground = (item.name == "Focus Theme: Midnight Blue") || (item.name == "Background: Yellow–Blue Gradient")
                        let isEquipped: Bool = {
                            if item.name == "Focus Theme: Midnight Blue" { return selectedBackground == "midnight" }
                            if item.name == "Background: Yellow–Blue Gradient" { return selectedBackground == "gradient" }
                            return false
                        }()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(item.cost) coins")
                                    .font(.caption.bold())
                                    .padding(6)
                                    .background(Color.yellow.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                if isOwned && !isBackground {
                                    Text("Owned")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }

                        HStack {
                            Spacer()
                            Button {
                                if isBackground {
                                    if isOwned {
                                        // Equip without cost
                                        if item.name == "Focus Theme: Midnight Blue" { selectedBackground = "midnight" }
                                        else if item.name == "Background: Yellow–Blue Gradient" { selectedBackground = "gradient" }
                                        return
                                    }
                                }

                                // Prevent re-purchasing owned items (non-backgrounds)
                                if isOwned { return }

                                // Guard for insufficient funds
                                guard coins >= item.cost else {
                                    showInsufficientFundsAlert = true
                                    return
                                }

                                // Deduct coins
                                coins -= item.cost

                                // Apply effects for purchased item(s)
                                if item.name == "Focus Theme: Midnight Blue" {
                                    useMidnightBlueTheme = true
                                    selectedBackground = "midnight"
                                } else if item.name == "Background: Yellow–Blue Gradient" {
                                    useGradientTheme = true
                                    selectedBackground = "gradient"
                                }
                                // TODO: Add unlock logic for other items
                            } label: {
                                if isBackground {
                                    if isOwned {
                                        Label(isEquipped ? "Equipped" : "Equip", systemImage: isEquipped ? "checkmark.circle" : "paintbrush")
                                    } else {
                                        Label("Buy", systemImage: "cart.badge.plus")
                                    }
                                } else {
                                    Label(isOwned ? "Owned" : "Buy", systemImage: isOwned ? "checkmark.circle" : "cart.badge.plus")
                                }
                            }
                            .buttonStyle(FilledButtonStyle(color: Color.accentColor))
                            .disabled(isBackground ? false : isOwned)
                            .opacity(isBackground ? 1.0 : (isOwned ? 0.6 : 1.0))
                            Spacer()

                            if isBackground && isEquipped {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Shop")
        .alert("Not enough coins", isPresented: $showInsufficientFundsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You don’t have enough coins to buy this item yet. Complete more focus sessions to earn more.")
        }
    }
}
