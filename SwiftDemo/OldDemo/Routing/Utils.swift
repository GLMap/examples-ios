//
//  Utils.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import Foundation

struct DelayedBlock {
    private var pendingItem: DispatchWorkItem?
    private let delay: TimeInterval
    private let block: () -> Void

    init(delay: TimeInterval, block: @escaping () -> Void) {
        self.delay = delay
        self.block = block
    }

    mutating func cancel() {
        pendingItem?.cancel()
        pendingItem = nil
    }

    mutating func perform() {
        cancel()
        let item = DispatchWorkItem(block: block)
        pendingItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func performNow() {
        block()
    }
}

final class ReadWriteLock {
    private var lock: pthread_rwlock_t
    init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }

    func writeLock() {
        pthread_rwlock_wrlock(&lock)
    }

    func readLock() {
        pthread_rwlock_rdlock(&lock)
    }

    func unlock() {
        pthread_rwlock_unlock(&lock)
    }
}

@propertyWrapper
struct AtomicRW<T> {
    private var storage: T
    private let lock: ReadWriteLock

    init(wrappedValue: T) {
        lock = ReadWriteLock()
        storage = wrappedValue
    }

    var wrappedValue: T {
        get {
            lock.readLock()
            let rv = storage
            lock.unlock()
            return rv
        }
        set {
            lock.writeLock()
            storage = newValue
            lock.unlock()
        }
    }
}

class Task: Equatable {
    @AtomicRW var isCancelled = false

    func start(_: @escaping () -> Void) {}

    func cancel() {
        isCancelled = true
    }

    func isEqual(to: Task) -> Bool {
        return self === to
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.isEqual(to: rhs)
    }
}

class OneTaskGuard<T: Task> {
    private var onTaskFinished: ((T?) -> Void)?
    private(set) var lastQuery: T?
    private var running, next: T?

    init(onTaskFinished: ((T?) -> Void)? = nil) {
        self.onTaskFinished = onTaskFinished
    }

    private func taskIsFinished() {
        //    LogPrint(@"Task is finished: %@, next: %@", [_running description], [_next description]);
        if let next {
            self.next = nil
            running = nil
            push(next)
        } else {
            // _running будет nil в одном случае, если мы сделали push:nil и уже уведомили о том что результаты очистились.
            if let running = running, !running.isCancelled {
                lastQuery = running
            }
            running = nil
            if let result = lastQuery {
                onTaskFinished?(result)
            }
        }
    }

    @discardableResult
    func push(_ task: T?, forceStart: Bool = false, onTaskFinished: ((T?) -> Void)? = nil) -> Bool {
        if let onTaskFinished {
            self.onTaskFinished = onTaskFinished
        }

        if let task {
            if let running {
                if forceStart || task != running {
                    // LogPrint(@"Not equal running: %@, new: %@", [_running description], [task description]);
                    next = task
                    running.cancel()
                    return true
                } else if task == lastQuery {
                    // LogPrint(@Eequal result: %@, new: %@", [_result description], [task description]);
                    next = nil
                    running.cancel()
                }
                return false
            } else {
                if forceStart || task != lastQuery {
                    // LogPrint(@"No running start: %@", [task description]);
                    running = task
                    running?.start { [weak self] in self?.taskIsFinished() }
                    return true
                }
                return false
            }
        } else {
            next = nil
            lastQuery = nil
            if let running {
                self.running = nil
                running.cancel()
            }
            self.onTaskFinished?(nil)
            return true
        }
    }
}
