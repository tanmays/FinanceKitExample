//
//  Untitled.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import Foundation
import FinanceKit

extension Decimal {
	var doubleValue: Double {
		return NSDecimalNumber(decimal: self).doubleValue
	}
}

@available(iOS 17.4, *)
extension AccountBalance {
	var amount: Double? {
		switch currentBalance {
		case .available(let available):
			let value = available.amount.amount.doubleValue
			return available.creditDebitIndicator == .debit ? value : -value
		case .booked(let booked):
			let value = booked.amount.amount.doubleValue
			return booked.creditDebitIndicator == .debit ? value : -value
		case .availableAndBooked(available: let available, booked: _):
			// When both are availble use the latest available value
			let value = available.amount.amount.doubleValue
			return available.creditDebitIndicator == .debit ? value : -value
		@unknown default:
			return nil
		}
	}
	
	var date: Date? {
		switch currentBalance {
		case .available(let available):
			return available.asOfDate
		case .booked(let booked):
			return booked.asOfDate
		case .availableAndBooked(available: let available, booked: _):
			return available.asOfDate
		@unknown default:
			return nil
		}
	}
}
