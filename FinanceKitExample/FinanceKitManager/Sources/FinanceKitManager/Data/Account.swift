//
//  Account.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import Foundation
import FinanceKit

@available(iOS 17.4, *)
public class Account: Codable, Identifiable {
	public enum AccountType: String, Codable, CaseIterable {
		case bank = "bank"
		case creditCard = "creditCard"

		public var title: String {
			get {
				switch self {
				case .creditCard: return "Credit Card"
				case .bank: return "Bank"
				}
			}
		}
	}
	
	public var id: String = UUID().uuidString
	public var title: String
	public var institutionName: String?
	public var desc: String?
	public var type: AccountType
	public var createdAt: Date
	public var updatedAt: Date?
	public var currencyCode: String = "USD"
	public var details = AccountDetails()
	public var balances: [Balance] = []
	public var dues: [Due] = []
	
	internal init(id: String = UUID().uuidString, type: Account.AccountType, title: String) {
		self.id = id
		self.type = type
		self.title = title
		self.createdAt = Date()
	}
	
	convenience init?(financeKitAccount: FinanceKit.Account) {
		let type: AccountType
		switch financeKitAccount {
		case .asset(_): type = .bank
		case .liability(_): type = .creditCard
		@unknown default: return nil
		}
		
		self.init(id: financeKitAccount.id.uuidString, type: type, title: financeKitAccount.displayName)
		createdAt = Date()
		update(from: financeKitAccount)
	}
	
	func update(from financeKitAccount: FinanceKit.Account) {
		// Account details
		let accountDetails = AccountDetails()
		if let liabilityAccount = financeKitAccount.liabilityAccount {
			if #available(iOS 18, *) {
				accountDetails.openingDate = financeKitAccount.openingDate
			}
			if let creditLimitValue = liabilityAccount.creditInformation.creditLimit {
				accountDetails.creditLimit = creditLimitValue.amount.doubleValue
			}
			if let minimumNextPaymentAmountValue = liabilityAccount.creditInformation.minimumNextPaymentAmount {
				accountDetails.minimumNextPaymentAmount = minimumNextPaymentAmountValue.amount.doubleValue
			}
			if let overduePaymentAmountValue = liabilityAccount.creditInformation.overduePaymentAmount {
				accountDetails.overduePaymentAmount = overduePaymentAmountValue.amount.doubleValue
			}
			accountDetails.nextPaymentDueDate = liabilityAccount.creditInformation.nextPaymentDueDate
		}
		self.details = accountDetails
		// Update dues array
		if let due = Due(accountDetails: accountDetails),
		   self.dues.first(where: {$0.dueAt == due.dueAt}) == nil {
			self.dues.append(due)
		}

		currencyCode = financeKitAccount.currencyCode
		institutionName = financeKitAccount.institutionName
		desc = financeKitAccount.accountDescription
		updatedAt = Date()
	}
	
	// MARK: - Balances
	func financeKitBalancesUpdated(inserted: [FinanceKit.AccountBalance], updated: [FinanceKit.AccountBalance], deleted: [UUID]) async {
		if !inserted.isEmpty {
			print("FinanceKit: Found \(inserted.count) new balances for \(self.title).")
			for financeKitBalance in inserted {
				guard let balance = Balance(financeKitBalance: financeKitBalance) else {
					continue
				}
				self.balances.append(balance)
			}
		}
		
		if !updated.isEmpty {
			print("FinanceKit: Found \(updated.count) updated balances for \(self.title).")
			for financeKitBalance in updated {
				guard let existingBalance = balances.first(where: {$0.id == financeKitBalance.id}) else {
					continue
				}
				existingBalance.update(using: financeKitBalance)
			}
		}
		
		if !deleted.isEmpty {
			print("FinanceKit: \(deleted.count) deleted balances for \(self.title).")
			for financeKitBalanceID in deleted {
				self.balances.removeAll(where: {$0.id == financeKitBalanceID})
			}
		}
		
		DataService.shared.update(accounts: [self])
	}
	
	// MARK: - Transactions
	func financeKitTransactionsUpdated(inserted: [FinanceKit.Transaction], updated: [FinanceKit.Transaction], deleted: [UUID]) async {
		
		if !inserted.isEmpty {
			print("FinanceKit: Found \(inserted.count) new txns for \(self.title).")
			var newTransactions = [Transaction]()
			for financeKitTransaction in inserted {
				guard let transaction = Transaction(financeKitTransaction: financeKitTransaction) else { continue }
				transaction.account = self
				newTransactions.append(transaction)
			}
			if !newTransactions.isEmpty {
				DataService.shared.add(transactions: newTransactions)
			}
		}
		
		if !updated.isEmpty {
			print("FinanceKit: Found \(updated.count) updated txns for \(self.title).")
			var updatedTransactions = [Transaction]()
			for financeKitTransaction in updated {
				guard let existingTransaction = DataService.shared.transactions.first(where: {$0.id == financeKitTransaction.id}) else { continue }
				existingTransaction.update(using: financeKitTransaction)
				existingTransaction.account = self
				updatedTransactions.append(existingTransaction)
			}
			if !updatedTransactions.isEmpty {
				DataService.shared.update(transactions: updatedTransactions)
			}
		}
		
		if !deleted.isEmpty {
			print("FinanceKit: \(updated.count) deleted txns for \(self.title).")
			var deletedTransactions = [Transaction]()
			for financeKitTransaction in updated {
				guard let existingTransaction = DataService.shared.transactions.first(where: {$0.id == financeKitTransaction.id}) else { continue }
				deletedTransactions.append(existingTransaction)
			}
			let _ = deletedTransactions.map({DataService.shared.delete(transaction: $0)})
		}
	}
}

@available(iOS 17.4, *)
public class AccountDetails: Codable {
	public var name: String = ""
	public var number: String = ""
	public var cvv: String = ""
	public var expiry: String = ""
	public var routingCode: String = ""
	public 	var branch: String = ""
	public 	var type: String = ""
	
	public var openingDate: Date? = nil
	public var creditLimit: Double? = nil
	public var nextPaymentDueDate: Date? = nil
	public var minimumNextPaymentAmount: Double? = nil
	public var overduePaymentAmount: Double? = nil
}
