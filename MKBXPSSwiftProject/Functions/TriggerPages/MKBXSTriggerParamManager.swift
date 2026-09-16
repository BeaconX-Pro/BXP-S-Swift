//
//  MKBXSTriggerParamManager.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

public final class MKBXSTriggerParamManager: NSObject, @unchecked Sendable {

    public static var shared: MKBXSTriggerParamManager = MKBXSTriggerParamManager()
    private static let lock = NSLock()

    public static func sharedDealloc() {
        lock.lock()
        defer { lock.unlock() }
        shared = MKBXSTriggerParamManager()
    }

    public var slotIndex: Int = 0 {
        didSet { rebuildModels() }
    }

    public private(set) var stepOneModel = MKBXSTriggerStepOneModel(slotIndex: 0)
    public private(set) var stepTwoModel = MKBXSTriggerStepTwoModel(slotIndex: 0)
    public private(set) var stepThreeModel = MKBXSTriggerStepThreeModel(slotIndex: 0)

    private let readQueue = DispatchQueue(label: "triggerParamsQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    private override init() {
        super.init()
    }

    private func rebuildModels() {
        stepOneModel = MKBXSTriggerStepOneModel(slotIndex: slotIndex)
        stepTwoModel = MKBXSTriggerStepTwoModel(slotIndex: slotIndex)
        stepThreeModel = MKBXSTriggerStepThreeModel(slotIndex: slotIndex)
    }

    // MARK: - Public

    public func fetchStepThreeAlert() -> String {
        switch stepOneModel.fetchTriggerType() {
        case 0: return fetchTemperatureTriggerMsg()
        case 1: return fetchHumidityTriggerMsg()
        case 2: return fetchMotionTriggerMsg()
        case 3: return fetchHallTriggerMsg()
        default: return ""
        }
    }

    public func read(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readStepOneModel() else {
                self.operationFailed("Read Step One Data Error", failedBlock: failedBlock); return
            }
            guard self.readStepTwoModel() else {
                self.operationFailed("Read Step Two Data Error", failedBlock: failedBlock); return
            }
            guard self.readStepThreeModel() else {
                self.operationFailed("Read Step Three Data Error", failedBlock: failedBlock); return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    public func config(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.configStepOneModel() else {
                self.operationFailed("Config Step One Data Error", failedBlock: failedBlock); return
            }
            if !self.stepOneModel.trigger {
                self.stepTwoModel.slotType = .null
                self.stepThreeModel.slotType = .null
            }
            guard self.configStepTwoModel() else {
                self.operationFailed("Config Step Two Data Error", failedBlock: failedBlock); return
            }
            guard self.configStepThreeModel() else {
                self.operationFailed("Config Step Three Data Error", failedBlock: failedBlock); return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    // MARK: - Private - Read/Config

    private func readStepOneModel() -> Bool {
        var success = false
        stepOneModel.read(sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configStepOneModel() -> Bool {
        var success = false
        stepOneModel.config(sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readStepTwoModel() -> Bool {
        var success = false
        stepTwoModel.read(sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configStepTwoModel() -> Bool {
        var success = false
        stepTwoModel.config(sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readStepThreeModel() -> Bool {
        var success = false
        stepThreeModel.read(sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configStepThreeModel() -> Bool {
        var success = false
        stepThreeModel.config(sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    // MARK: - Private - Helper

    private func fetchIntervalMsgValue(_ interval: String) -> String {
        "\((Int(interval) ?? 0) * 100)"
    }

    // MARK: - Temperature Trigger Msg

    private func fetchTemperatureTriggerMsg() -> String {
        let stepOne = stepOneModel
        let stepTwo = stepTwoModel
        let stepThree = stepThreeModel
        let interval2 = fetchIntervalMsgValue(stepTwo.advInterval)
        let interval3 = fetchIntervalMsgValue(stepThree.advInterval)

        if stepOne.tempEvent == 0 {
            // Above
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device temperature is more than or equal to \(stepOne.temperature)℃, and stop advertising immediately after device temperature is less than \(stepOne.temperature)℃"
                    }
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device temperature is more than or equal to \(stepOne.temperature)℃.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if (Int(stepTwo.advDuration) ?? 0) == 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(interval2)ms after device temperature is more than or equal to \(stepOne.temperature)℃, and stop advertising immediately after device temperature is less than \(stepOne.temperature)℃"
                    }
                    return "*The Beacon will keep advertising at the interval of \(interval2)ms after device temperature is more than or equal to \(stepOne.temperature)℃, and stop advertising after device temperature is less than \(stepOne.temperature)℃.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                return ""
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when device temperature is more than or equal to \(stepOne.temperature)℃, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device temperature is less than \(stepOne.temperature)℃"
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when device temperature is more than or equal to \(stepOne.temperature)℃, and keep advertising at the interval of \(interval3)ms when device temperature is less than \(stepOne.temperature)℃"
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device temperature is more than or equal to \(stepOne.temperature)℃, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device temperature is less than \(stepOne.temperature)℃."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device temperature is more than or equal to \(stepOne.temperature)℃, and keep advertising at the interval of \(interval3)ms when device temperature is less than \(stepOne.temperature)℃"
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            return ""
        }

        if stepOne.tempEvent == 1 {
            // Below
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device temperature is less than or equal to \(stepOne.temperature)℃, and stop advertising immediately after device temperature is more than \(stepOne.temperature)℃."
                    }
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device temperature is less than or equal to \(stepOne.temperature)℃.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if (Int(stepTwo.advDuration) ?? 0) == 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(interval2)ms after device temperature is less than or equal to \(stepOne.temperature)℃, and stop advertising immediately after device temperature is more than \(stepOne.temperature)℃"
                    }
                    return "*The Beacon will keep advertising at the interval of \(interval2)ms after device temperature is less than or equal to \(stepOne.temperature)℃, and stop advertising after device temperature is more than \(stepOne.temperature)℃.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                return ""
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when device temperature is less than or equal to \(stepOne.temperature)℃, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device temperature is more than \(stepOne.temperature)℃."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when device temperature is less than or equal to \(stepOne.temperature)℃, and keep advertising at the interval of \(interval3)ms when device temperature is more than \(stepOne.temperature)℃."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device temperature is less than or equal to \(stepOne.temperature)℃, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device temperature is more than \(stepOne.temperature)℃."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device temperature is less than or equal to \(stepOne.temperature)℃, and keep advertising at the interval of \(interval3)ms when device temperature is more than \(stepOne.temperature)℃"
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            return ""
        }
        return ""
    }

    // MARK: - Humidity Trigger Msg

    private func fetchHumidityTriggerMsg() -> String {
        let stepOne = stepOneModel
        let stepTwo = stepTwoModel
        let stepThree = stepThreeModel
        let interval2 = fetchIntervalMsgValue(stepTwo.advInterval)
        let interval3 = fetchIntervalMsgValue(stepThree.advInterval)

        if stepOne.humidityEvent == 0 {
            // Above
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device Himidity is more than or equal to \(stepOne.humidity)%, and stop advertising immediately after device Himidity is less than \(stepOne.humidity)%."
                    }
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device Himidity is more than or equal to \(stepOne.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if (Int(stepTwo.advDuration) ?? 0) == 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(interval2)ms after device Himidity is more than or equal to \(stepOne.humidity)%, and stop advertising immediately after device Himidity is less than \(stepOne.humidity)%."
                    }
                    return "*The Beacon will keep advertising at the interval of \(interval2)ms after device Himidity is more than or equal to \(stepOne.humidity)%, and stop advertising after device Himidity is less than \(stepOne.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                return ""
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for\(stepTwo.advDuration)s at the interval of \(interval2)ms when device Himidity is more than or equal to \(stepOne.humidity)%, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device Himidity is less than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when device Himidity is more than or equal to \(stepOne.humidity)%, and keep advertising at the interval of \(interval3)ms when device Himidity is less than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device Himidity is more than or equal to \(stepOne.humidity)%, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device Himidity is less than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device Himidity is more than or equal to \(stepOne.humidity)%, and  keep advertising at the interval of \(interval3)ms when device Himidity is less than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            return ""
        }
        if stepOne.humidityEvent == 1 {
            // Below
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device Himidity is less than or equal to \(stepOne.humidity)%, and stop advertising immediately after device Himidity is more than \(stepOne.humidity)%."
                    }
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device Himidity is less than or equal to \(stepOne.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if (Int(stepTwo.advDuration) ?? 0) == 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(interval2)ms after device Himidity is less than or equal to \(stepOne.humidity)%, and stop advertising immediately after device Himidity is more than \(stepOne.humidity)%."
                    }
                    return "*The Beacon will keep advertising  at the interval of \(interval2)ms after device Himidity is less than or equal to \(stepOne.humidity)%, and stop advertising after device Himidity is more than \(stepOne.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                return ""
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when device Himidity is less than or equal to \(stepOne.humidity)%, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device Himidity is more than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when device Himidity is less than or equal to \(stepOne.humidity)%, and  keep advertising at the interval of \(interval3)ms when device Himidity is more than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device Himidity is less than or equal to \(stepOne.humidity)%, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device Himidity is more than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms when device Himidity is less than or equal to \(stepOne.humidity)%, and keep advertising at the interval of \(interval3)ms when device Himidity is more than \(stepOne.humidity)%."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            return ""
        }
        return ""
    }

    // MARK: - Motion Trigger Msg

    private func fetchMotionTriggerMsg() -> String {
        let stepOne = stepOneModel
        let stepTwo = stepTwoModel
        let stepThree = stepThreeModel
        let interval2 = fetchIntervalMsgValue(stepTwo.advInterval)
        let interval3 = fetchIntervalMsgValue(stepThree.advInterval)

        if stepOne.motionEvent == 0 {
            // Device start moving
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device moves, and stop advertising immediately after device keep stationary for \(stepOne.motionVerificationPeriod)s"
                }
                return "*The Beacon will start advertising for \(stepOne.motionVerificationPeriod)s at the interval of \(interval2)ms after device moves, and stop advertising immediately after device keep stationary for \(stepOne.motionVerificationPeriod)s"
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    return "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device moves, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device keep stationary for \(stepOne.motionVerificationPeriod)s"
                }
                return "*The Beacon will advertising for \(stepOne.motionVerificationPeriod)s at the interval of \(interval2)ms after device moves, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when device keep stationary for \(stepOne.motionVerificationPeriod)s"
            }
            if (Int(stepTwo.advDuration) ?? 0) > 0 {
                return "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device moves, and  keep advertising at the interval of \(interval3)ms when device keep stationary for \(stepOne.motionVerificationPeriod)s"
            }
            return "*The Beacon will advertising for \(stepOne.motionVerificationPeriod)s at the interval of \(interval2)ms after device moves, and  keep advertising at the interval of \(interval3)ms when device keep stationary for \(stepOne.motionVerificationPeriod)s"
        }
        if stepOne.motionEvent == 1 {
            // Device remains stationary
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device keep stationary for \(stepOne.motionVerificationPeriod)s, and stop advertising immediately when device moves."
                }
                return "*The Beacon will keep advertising at the interval of \(interval2)ms after device keep stationary for \(stepOne.motionVerificationPeriod)s, and stop advertising immediately when device moves."
            }
            if (Int(stepTwo.advDuration) ?? 0) > 0 {
                return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after device keep stationary for \(stepOne.motionVerificationPeriod)s, and advertising for \(stepOne.motionVerificationPeriod)s at the interval of \(interval3)ms when device moves."
            }
            return "*The Beacon will keep advertising at the interval of \(interval2)ms after device keep stationary for \(stepOne.motionVerificationPeriod)s, and advertising for StaticVs at the interval of \(interval3)ms when device moves. "
        }
        return ""
    }

    // MARK: - Hall Trigger Msg

    private func fetchHallTriggerMsg() -> String {
        let stepOne = stepOneModel
        let stepTwo = stepTwoModel
        let stepThree = stepThreeModel
        let interval2 = fetchIntervalMsgValue(stepTwo.advInterval)
        let interval3 = fetchIntervalMsgValue(stepThree.advInterval)

        if stepOne.hallEvent == 0 {
            // Door open
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after door open, and stop advertising immediately when door close."
                    }
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms when door open.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if (Int(stepTwo.advDuration) ?? 0) == 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(interval2)ms after door open, and stop advertising immediately when door close."
                    }
                    return "*The Beacon will keep advertising at the interval of \(interval2)ms after door open, and stop advertising when door close.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                return ""
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after door open, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when door close."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after door open,and keep advertising at the interval of \(interval3)ms when door close."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms after door open, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when door close."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms after door open, and keep advertising at the interval of \(interval3)ms when door close."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            return ""
        }
        if stepOne.hallEvent == 1 {
            // Door close
            if !stepThree.trigger {
                if (Int(stepTwo.advDuration) ?? 0) > 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after door close, and stop advertising immediately when door open."
                    }
                    return "*The Beacon will start advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after door close.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if (Int(stepTwo.advDuration) ?? 0) == 0 {
                    if !stepOne.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(interval2)ms after door close, and stop advertising immediately when door open."
                    }
                    return "*The Beacon will keep advertising  at the interval of \(interval2)ms after door close, and stop advertising when door open.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                return ""
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after door close, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when door open."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) > 0 {
                var msg = "*The Beacon will advertising for \(stepTwo.advDuration)s at the interval of \(interval2)ms after door close, and keep advertising at the interval of \(interval3)ms when door open."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) > 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms after door close, and advertising for \(stepThree.advDuration)s every \(stepThree.standbyDuration)s at the interval of \(interval3)ms when door open."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            if (Int(stepThree.standbyDuration) ?? 0) == 0 && (Int(stepTwo.advDuration) ?? 0) == 0 {
                var msg = "*The Beacon will keep advertising at the interval of \(interval2)ms after door close, and keep advertising at the interval of \(interval3)ms when door open."
                if stepOne.lockedAdvIsOn {
                    msg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return msg
            }
            return ""
        }
        return ""
    }

    // MARK: - Error

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "triggerParams", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
