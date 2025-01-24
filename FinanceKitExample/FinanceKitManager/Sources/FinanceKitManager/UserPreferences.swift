//
//  UserPreferences.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import Foundation

@available(iOS 17.4, *)
class UserPreferences {
	static let userDefaults = UserDefaults.init(suiteName: "group.me.tanmay.FinanceApp")!
	
	// MARK: Accounts
	
	static func loadAccountsFromDisk() -> [Account] {
		guard let data = Self.userDefaults.data(forKey: "FinanceKit.Accounts") else { return [] }
		let accounts = try? JSONDecoder().decode([Account].self, from: data)
		return accounts ?? []
	}
	
	static func saveAccountsToDisk(_ accounts: [Account]) {
		DispatchQueue.global(qos: .background).async {
			guard let encoded = try? JSONEncoder().encode(accounts) else { return }
			Self.userDefaults.set(encoded, forKey: "FinanceKit.Accounts")
			Self.userDefaults.synchronize()
		}
	}
	
	// MARK: Transactions
	
	static func loadTransactionsFromDisk() -> [Transaction] {
		guard let data = Self.userDefaults.data(forKey: "FinanceKit.Transactions") else { return [] }
		let txns = try? JSONDecoder().decode([Transaction].self, from: data)
		return txns ?? []
	}
	
	static func saveTransactionsToDisk(_ transactions: [Transaction]) {
		DispatchQueue.global(qos: .background).async {
			guard let encoded = try? JSONEncoder().encode(transactions) else { return }
			Self.userDefaults.set(encoded, forKey: "FinanceKit.Transactions")
			Self.userDefaults.synchronize()
		}
	}
}
