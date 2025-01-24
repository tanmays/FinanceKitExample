//
//  AccountDataService.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import SwiftUI
import Combine
import FinanceKit

@available(iOS 17.4, *)
public class DataService: ObservableObject {
	static let shared = DataService()
	@Published public private(set) var accounts: [Account] = []
	@Published public private(set) var transactions: [Transaction] = []
	
	private init() {
		self.accounts = UserPreferences.loadAccountsFromDisk()
		self.transactions = UserPreferences.loadTransactionsFromDisk()
	}
	
	// MARK: - Transactions
	func add(transactions: [Transaction]) {
		self.transactions.append(contentsOf: transactions)
		UserPreferences.saveTransactionsToDisk(transactions)
	}
	
	func update(transactions: [Transaction]) {
		for updated in transactions {
			if let index = self.transactions.firstIndex(where: {$0.id == updated.id}) {
				self.transactions.remove(at: index)
				self.transactions.append(updated)
				print("Updated existing txn \(updated.desc).")
			} else {
				print("Existing txn \(updated.desc) not found, adding new.")
				self.transactions.append(updated)
			}
		}
		UserPreferences.saveTransactionsToDisk(transactions)
	}
	
	func delete(transaction: Transaction) {
		guard let index = self.transactions.firstIndex(where: {$0.id == transaction.id}) else {
			print("Existing transaction named \(transaction.desc) not found. Unable to delete.")
			return
		}
		self.transactions.remove(at: index)
		print("Deleted existing txn \(transaction.desc).")
		UserPreferences.saveTransactionsToDisk(transactions)
	}

	// MARK: - Accounts
	func add(accounts: [Account]) {
		self.accounts.append(contentsOf: accounts)
		UserPreferences.saveAccountsToDisk(accounts)
	}
	
	func update(accounts: [Account]) {
		for updatedAccount in accounts {
			if let index = self.accounts.firstIndex(where: {$0.id == updatedAccount.id}) {
				self.accounts.remove(at: index)
				self.accounts.append(updatedAccount)
				print("Updated existing account \(updatedAccount.title).")
			} else {
				print("Existing account \(updatedAccount.title) not found, adding new.")
				self.accounts.append(updatedAccount)
			}
		}
		UserPreferences.saveAccountsToDisk(accounts)
	}
	
	func delete(account: Account) {
		guard let index = self.accounts.firstIndex(where: {$0.id == account.id}) else {
			print("Existing account named \(account.title) not found. Unable to delete.")
			return
		}
		self.accounts.remove(at: index)
		print("Deleted existing account \(account.title).")
		UserPreferences.saveAccountsToDisk(accounts)
	}

	func financeKitAccountsUpdated(inserted: [FinanceKit.Account], updated: [FinanceKit.Account], deleted: [UUID]) async {
		// Inserted - New Accounts
		if !inserted.isEmpty {
			print("FinanceKit: Found \(inserted.count) new accounts.")
			// Create new accounts
			var newAccounts = [Account]()
			for financeKitAccount in inserted {
				guard let account = Account(financeKitAccount: financeKitAccount) else { continue }
				newAccounts.append(account)
			}
			self.add(accounts: newAccounts)
			DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
				Task { try? await FinanceKitManager.shared.autoSyncBalancesAndTransactionsIfNeeded() }
			}
		}
		
		// Updated - Existing Accounts
		if !updated.isEmpty {
			print("FinanceKit: \(updated.count) accounts updated.")
			// Update existing accounts
			var updatedAccounts = [Account]()
			for financeKitAccount in updated {
				guard let localAccount = accounts.first(where: {$0.id == financeKitAccount.id.uuidString}) else {
					print("WARNING: An account from Apple Wallet named \(financeKitAccount.displayName) was not found. Please investigate.")
					continue
				}
				updatedAccounts.append(localAccount)
			}
			
			self.update(accounts: updatedAccounts)
		}
		
		// Delete
		if !deleted.isEmpty {
			print("FinanceKit: Deleted \(deleted.count) accounts.")
			// TODO: Ideally show a warning to the user that an account has been deleted in Wallet.
			// For now simply delete the account without prompting.
			for idToDelete in deleted {
				guard let localAccount = accounts.first(where: {$0.id == idToDelete.uuidString}) else {
					print("WARNING: An account from Apple Wallet with id \(idToDelete.uuidString) was not found for deletion. Please investigate.")
					continue
				}
				FinanceKitManager.shared.stopSyncing(account: localAccount)
				self.delete(account: localAccount)
			}
		}
	}
}
