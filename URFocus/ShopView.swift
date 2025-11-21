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
            cost: 300
        ),
        .init(
            name: "Sticker Pack: Study Gremlins",
            description: "Silly little critters to cheer you on in the UI.",
            cost: 500
        ),
        .init(
            name: "Title: Library Goblin",
            description: "Show off your streak with a goofy profile title.",
            cost: 800
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
                        let isOwned = (item.name == "Focus Theme: Midnight Blue") && useMidnightBlueTheme

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

                                if isOwned {
                                    Text("Owned")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }

                        HStack {
                            Spacer()
                            Button {
                                // Prevent re-purchasing owned items
                                if isOwned {
                                    return
                                }

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
                                }
                                // TODO: Add unlock logic for other items
                            } label: {
                                Label(
                                    isOwned ? "Owned" : "Buy",
                                    systemImage: isOwned ? "checkmark.circle" : "cart.badge.plus"
                                )
                            }
                            .buttonStyle(FilledButtonStyle(color: Color.accentColor))
                            .disabled(isOwned)
                            .opacity(isOwned ? 0.6 : 1.0)
                            Spacer()
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