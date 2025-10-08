import Foundation
import HealthKit

public actor HealthStoreManager {
    public static let shared = HealthStoreManager()

    private let healthStore = HKHealthStore()

    private init() {}

    public func requestAuthorizationIfNeeded() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [sleepType], read: [sleepType]) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: AuthorizationError.notGranted)
                }
            }
        }
    }

    public func saveInBedSession(start: Date, end: Date) async throws {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: start,
            end: end
        )

        try await withCheckedThrowingContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: AuthorizationError.notGranted)
                }
            }
        }
    }

    public enum AuthorizationError: Error {
        case notGranted
    }
}
