//
//  CustomError.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import Foundation

enum CustomError: LocalizedError {
	case message(_ text: String)
	
	public var errorDescription: String? {
		switch self {
		case .message(let text): return text
		}
	}
}
