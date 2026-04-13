// calendar-events — Query macOS Calendar via EventKit and output JSON
//
// Build:
//   swiftc -O calendar-events.swift -o calendar-events -framework EventKit -framework Foundation
//
// Usage:
//   calendar-events [--minutes N]      Query events in the next N minutes (default: 60)
//   calendar-events [--output FILE]    Write JSON to FILE instead of stdout
//   calendar-events --request-access   Just request calendar permission and report status
//
// Exit codes: 0 = success, 1 = permission denied, 2 = other error

import Foundation
import EventKit

let store = EKEventStore()

// MARK: - Argument parsing

var minutes: Int = 60
var requestAccessOnly = false
var outputPath: String? = nil

var args = CommandLine.arguments.dropFirst()
while let arg = args.first {
    args = args.dropFirst()
    switch arg {
    case "--minutes":
        guard let next = args.first, let val = Int(next) else {
            fputs("Error: --minutes requires an integer\n", stderr)
            exit(2)
        }
        minutes = val
        args = args.dropFirst()
    case "--output":
        guard let next = args.first else {
            fputs("Error: --output requires a file path\n", stderr)
            exit(2)
        }
        outputPath = next
        args = args.dropFirst()
    case "--request-access":
        requestAccessOnly = true
    default:
        fputs("Unknown argument: \(arg)\n", stderr)
        exit(2)
    }
}

// MARK: - Request calendar access

func requestAccess() -> Bool {
    let semaphore = DispatchSemaphore(value: 0)
    var granted = false

    if #available(macOS 14.0, *) {
        store.requestFullAccessToEvents { ok, error in
            granted = ok
            if let error = error {
                fputs("EventKit error: \(error.localizedDescription)\n", stderr)
            }
            semaphore.signal()
        }
    } else {
        store.requestAccess(to: .event) { ok, error in
            granted = ok
            if let error = error {
                fputs("EventKit error: \(error.localizedDescription)\n", stderr)
            }
            semaphore.signal()
        }
    }

    semaphore.wait()
    return granted
}

// MARK: - Output helpers

func outputJSON(_ dict: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
          let str = String(data: data, encoding: .utf8) else { return }

    if let path = outputPath {
        do {
            try str.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            fputs("Error writing to \(path): \(error.localizedDescription)\n", stderr)
            exit(2)
        }
    } else {
        print(str)
    }
}

func exitPermissionDenied() -> Never {
    outputJSON([
        "events": [],
        "status": "permission_denied",
        "error": "Calendar access denied. Grant access in System Settings > Privacy & Security > Calendars."
    ])
    exit(1)
}

// MARK: - Main

let accessGranted = requestAccess()

if requestAccessOnly {
    if accessGranted {
        outputJSON(["status": "ok", "message": "Calendar access granted"])
    } else {
        exitPermissionDenied()
    }
    exit(accessGranted ? 0 : 1)
}

guard accessGranted else {
    exitPermissionDenied()
}

let now = Date()
let later = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
let predicate = store.predicateForEvents(withStart: now, end: later, calendars: nil)
let events = store.events(matching: predicate)

let eventDicts: [[String: Any]] = events.map { event in
    [
        "id": event.calendarItemIdentifier,
        "title": event.title ?? "(no title)",
        "startDate": Int(event.startDate.timeIntervalSince1970),
        "endDate": Int(event.endDate.timeIntervalSince1970),
        "calendar": event.calendar.title,
        "isAllDay": event.isAllDay
    ]
}

outputJSON([
    "events": eventDicts,
    "status": "ok"
])
