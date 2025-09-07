//
//  Date+Format.swift
//  PersonaChat
//
//  Created by Mohammed on 8/29/25.
//

import Foundation

extension Date {

    enum RelativeDate: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case older = "Older"
    }

    var relative: RelativeDate {
        if calendar.isDateInToday(self) {
            .today
        } else if calendar.isDateInYesterday(self) {
            .yesterday
        } else if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start,
                  self >= startOfWeek {
            .thisWeek
        } else {
            .older
        }
    }
}

fileprivate let calendar = Calendar.current
