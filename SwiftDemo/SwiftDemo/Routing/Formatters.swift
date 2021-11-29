//
//  Formatters.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import Foundation

class Formatters {
    static let si = Formatters()

    private lazy var nfNoFract: NumberFormatter = {
        let rv = NumberFormatter()
        rv.numberStyle = .decimal
        rv.locale = .autoupdatingCurrent
        rv.minimumIntegerDigits = 1
        rv.minimumFractionDigits = 0
        rv.maximumFractionDigits = 0
        return rv
    }()

    private lazy var nf1Fract: NumberFormatter = {
        let rv = NumberFormatter()
        rv.numberStyle = .decimal
        rv.locale = .autoupdatingCurrent
        rv.minimumIntegerDigits = 1
        rv.minimumFractionDigits = 1
        rv.maximumFractionDigits = 1
        return rv
    }()

    private lazy var hhMMDate: DateFormatter = {
        let rv = DateFormatter()
        rv.dateFormat = "HH:mm"
        return rv
    }()

    func format(speed: Double) -> (value: String, units: String) {
        if speed.isFinite, let valueStr = nfNoFract.string(from: NSNumber(value: round(speed * 3.6))) {
            return (valueStr, "km/h")
        }
        return ("---", "km/h")
    }

    func format(timestamp: TimeInterval) -> String {
        if !timestamp.isFinite {
            return "--:--"
        }
        return hhMMDate.string(from: Date(timeIntervalSinceReferenceDate: timestamp))
    }

    func format(duration: TimeInterval) -> String {
        if !duration.isFinite {
            return "-- min"
        }
        var duration = duration
        if duration < 60 {
            duration = 0
        }
        var minutes = Int(duration / 60)
        let hours = minutes / 60
        minutes -= hours * 60
        if let hoursStr = nfNoFract.string(from: NSNumber(value: hours)),
           let minutesStr = nfNoFract.string(from: NSNumber(value: minutes))
        {
            if hours == 0 {
                return "\(minutesStr) min"
            } else if hours < 10 {
                return "\(hoursStr) hours \(minutesStr) minutes"
            } else {
                return "\(hoursStr) hours"
            }
        } else {
            return "-- minutes"
        }
    }

    func format(distance: Double) -> String {
        var nf = nfNoFract
        let units: String
        let value: Double

        if distance.isFinite, distance >= 0 {
            if distance < 100 {
                value = round(distance / 10.0) * 10
                units = "m"
            } else if distance < 975 {
                value = round(distance / 50.0) * 50
                units = "m"
            } else {
                if distance < 10000 {
                    nf = nf1Fract
                }
                value = distance / 1000.0
                units = "km"
            }
        } else {
            value = Double.nan
            units = "m"
        }

        if value.isFinite, let valueStr = nf.string(from: NSNumber(value: value)) {
            return "\(valueStr) \(units)"
        }
        return "-- \(units)"
    }
}
