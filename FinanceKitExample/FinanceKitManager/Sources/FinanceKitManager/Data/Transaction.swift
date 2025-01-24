//
//  Transaction.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import Foundation
import FinanceKit

@available(iOS 17.4, *)
public class Transaction: Codable, Identifiable {
	public var id: UUID
	public var date: Date
	public var desc: String
	public var amount: Double
	public var currencyCode: String = "USD"
	public var account: Account?
	
	internal init(id: UUID = UUID(), date: Date, desc: String, amount: Double, currencyCode: String) {
		self.id = id
		self.date = date
		self.desc = desc
		self.amount = amount
		self.currencyCode = currencyCode
	}
	
	convenience init?(financeKitTransaction: FinanceKit.Transaction) {
		let amount: Double
		let currencyAmount = financeKitTransaction.transactionAmount
		switch financeKitTransaction.creditDebitIndicator {
		case .debit: amount = currencyAmount.amount.doubleValue
		case .credit: amount = -currencyAmount.amount.doubleValue
		@unknown default:
			amount = financeKitTransaction.transactionAmount.amount.doubleValue
		}
		self.init(id: financeKitTransaction.id,
				  date: financeKitTransaction.transactionDate,
				  desc: financeKitTransaction.originalTransactionDescription,
				  amount: amount,
				  currencyCode: currencyAmount.currencyCode)
		
		// merchangeCategoryCode, merchantName, transactionType
	}
	
	func update(using financeKitTransaction: FinanceKit.Transaction) {
		let amount: Double
		let currencyAmount = financeKitTransaction.transactionAmount
		switch financeKitTransaction.creditDebitIndicator {
		case .debit: amount = currencyAmount.amount.doubleValue
		case .credit: amount = -currencyAmount.amount.doubleValue
		@unknown default:
			amount = financeKitTransaction.transactionAmount.amount.doubleValue
		}
		
		self.date = financeKitTransaction.transactionDate
		self.desc = financeKitTransaction.originalTransactionDescription
		self.amount = amount
		self.currencyCode = currencyAmount.currencyCode
	}
}
