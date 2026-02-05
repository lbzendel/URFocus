import Foundation
import CloudKit

final class CloudKitService {
    static let shared = CloudKitService()

    private let database: CKDatabase
    private let sharedGoalRecordID = CKRecord.ID(recordName: "global")
    private let sharedGoalRecordType = "SharedGoal"
    private let leaderboardRecordType = "LeaderboardEntry"

    init(container: CKContainer = .default()) {
        self.database = container.publicCloudDatabase
    }

    func fetchSharedGoal(completion: @escaping (Result<SharedGoal, Error>) -> Void) {
        database.fetch(withRecordID: sharedGoalRecordID) { record, error in
            if let error = error as? CKError, error.code == .unknownItem {
                let record = CKRecord(recordType: self.sharedGoalRecordType, recordID: self.sharedGoalRecordID)
                record["sessionsCompleted"] = 0
                record["secondsFocused"] = 0
                record["goalTarget"] = 600_000
                record["updatedAt"] = Date()
                self.database.save(record) { saved, saveError in
                    if let saveError = saveError {
                        completion(.failure(saveError))
                        return
                    }
                    if let saved {
                        completion(.success(self.sharedGoal(from: saved)))
                        return
                    }
                    completion(.failure(CKError(.unknownItem)))
                }
                return
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let record else {
                completion(.failure(CKError(.unknownItem)))
                return
            }
            completion(.success(self.sharedGoal(from: record)))
        }
    }

    func recordSharedCompletion(seconds: Int, completion: ((Result<SharedGoal, Error>) -> Void)? = nil) {
        let safe = max(60, min(seconds, 6 * 3600))
        database.fetch(withRecordID: sharedGoalRecordID) { record, error in
            let recordToSave: CKRecord
            if let record {
                recordToSave = record
            } else {
                recordToSave = CKRecord(recordType: self.sharedGoalRecordType, recordID: self.sharedGoalRecordID)
            }

            let currentSessions = recordToSave.intValue(forKey: "sessionsCompleted")
            let currentSeconds = recordToSave.intValue(forKey: "secondsFocused")
            let currentTarget = recordToSave.intValue(forKey: "goalTarget")

            recordToSave["sessionsCompleted"] = currentSessions + 1
            recordToSave["secondsFocused"] = currentSeconds + safe
            recordToSave["goalTarget"] = currentTarget == 0 ? 600_000 : currentTarget
            recordToSave["updatedAt"] = Date()

            self.database.save(recordToSave) { saved, saveError in
                if let saveError = saveError {
                    completion?(.failure(saveError))
                    return
                }
                if let saved {
                    completion?(.success(self.sharedGoal(from: saved)))
                }
            }
        }
    }

    func updateLeaderboardEntry(
        userID: String,
        displayName: String,
        minutesFocused: Int,
        streakDays: Int,
        sessionsCompleted: Int
    ) {
        let recordID = CKRecord.ID(recordName: userID)
        database.fetch(withRecordID: recordID) { record, _ in
            let recordToSave = record ?? CKRecord(recordType: self.leaderboardRecordType, recordID: recordID)
            recordToSave["displayName"] = displayName
            recordToSave["minutesFocused"] = minutesFocused
            recordToSave["streakDays"] = streakDays
            recordToSave["sessionsCompleted"] = sessionsCompleted
            recordToSave["updatedAt"] = Date()
            self.database.save(recordToSave) { _, saveError in
                if let saveError = saveError {
                    print("CloudKit leaderboard save failed: \(saveError)")
                }
            }
        }
    }

    func fetchLeaderboard(
        sortedBy key: String,
        limit: Int,
        completion: @escaping (Result<[LeaderboardEntry], Error>) -> Void
    ) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: leaderboardRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: key, ascending: false)]

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = limit

        var entries: [LeaderboardEntry] = []

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                entries.append(self.leaderboardEntry(from: record))
            case .failure(let error):
                print("CloudKit leaderboard fetch error: \(error)")
            }
        }

        operation.queryResultBlock = { result in
            switch result {
            case .success:
                completion(.success(entries.sorted { $0[sortKey: key] > $1[sortKey: key] }))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        database.add(operation)
    }

    private func sharedGoal(from record: CKRecord) -> SharedGoal {
        SharedGoal(
            sessionsCompleted: record.intValue(forKey: "sessionsCompleted"),
            secondsFocused: record.intValue(forKey: "secondsFocused"),
            goalTarget: record.intValue(forKey: "goalTarget") == 0 ? 600_000 : record.intValue(forKey: "goalTarget"),
            updatedAt: record["updatedAt"] as? Date
        )
    }

    private func leaderboardEntry(from record: CKRecord) -> LeaderboardEntry {
        LeaderboardEntry(
            id: record.recordID.recordName,
            displayName: record["displayName"] as? String ?? "(anon)",
            minutesFocused: record.intValue(forKey: "minutesFocused"),
            streakDays: record.intValue(forKey: "streakDays")
        )
    }
}

private extension CKRecord {
    func intValue(forKey key: String) -> Int {
        if let number = self[key] as? NSNumber {
            return number.intValue
        }
        if let value = self[key] as? Int {
            return value
        }
        return 0
    }
}

private extension LeaderboardEntry {
    subscript(sortKey key: String) -> Int {
        switch key {
        case "minutesFocused":
            return minutesFocused
        case "streakDays":
            return streakDays
        default:
            return 0
        }
    }
}
