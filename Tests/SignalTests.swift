//
//  SignalTests.swift
//  Rex
//
//  Created by Neil Pankey on 5/9/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import Rex
import ReactiveCocoa
import XCTest

final class SignalTests: XCTestCase {

    func testFilterMap() {
        let (signal, sink) = Signal<Int, NoError>.pipe()
        var values: [String] = []

        signal
            .filterMap {
                return $0 % 2 == 0 ? String($0) : nil
            }
            .observe(Observer(next: { values.append($0) }))

        sink.sendNext(1)
        XCTAssert(values == [])

        sink.sendNext(2)
        XCTAssert(values == ["2"])

        sink.sendNext(3)
        XCTAssert(values == ["2"])

        sink.sendNext(6)
        XCTAssert(values == ["2", "6"])
    }

    func testIgnoreErrorCompletion() {
        let (signal, sink) = Signal<Int, TestError>.pipe()
        var completed = false

        signal
            .ignoreError()
            .observe(Observer(completed: {
                completed = true
            }))

        sink.sendNext(1)
        XCTAssertFalse(completed)

        sink.sendFailed(.Default)
        XCTAssertTrue(completed)
    }

    func testIgnoreErrorInterruption() {
        let (signal, sink) = Signal<Int, TestError>.pipe()
        var interrupted = false

        signal
            .ignoreError(replacement: .Interrupted)
            .observe(Observer(interrupted: {
                interrupted = true
            }))

        sink.sendNext(1)
        XCTAssertFalse(interrupted)

        sink.sendFailed(.Default)
        XCTAssertTrue(interrupted)
    }

    func testTimeoutAfterTerminating() {
        let scheduler = TestScheduler()
        let (signal, sink) = Signal<Int, NoError>.pipe()
        var interrupted = false
        var completed = false

        signal
            .timeoutAfter(2, withEvent: .Interrupted, onScheduler: scheduler)
            .observe(Observer(
                completed: { completed = true },
                interrupted: { interrupted = true }
            ))

        scheduler.scheduleAfter(1) { sink.sendCompleted() }

        XCTAssertFalse(interrupted)
        XCTAssertFalse(completed)

        scheduler.run()
        XCTAssertTrue(completed)
        XCTAssertFalse(interrupted)
    }

    func testTimeoutAfterTimingOut() {
        let scheduler = TestScheduler()
        let (signal, sink) = Signal<Int, NoError>.pipe()
        var interrupted = false
        var completed = false

        signal
            .timeoutAfter(2, withEvent: .Interrupted, onScheduler: scheduler)
            .observe(Observer(
                completed: { completed = true },
                interrupted: { interrupted = true }
            ))

        scheduler.scheduleAfter(3) { sink.sendCompleted() }

        XCTAssertFalse(interrupted)
        XCTAssertFalse(completed)

        scheduler.run()
        XCTAssertTrue(interrupted)
        XCTAssertFalse(completed)
    }

    func testUncollect() {
        let (signal, sink) = Signal<[Int], NoError>.pipe()
        var values: [Int] = []

        signal
            .uncollect()
            .observe(Observer(next: {
                values.append($0)
            }))

        sink.sendNext([])
        XCTAssert(values.isEmpty)

        sink.sendNext([1])
        XCTAssert(values == [1])

        sink.sendNext([2, 3])
        XCTAssert(values == [1, 2, 3])
    }
}

enum TestError: ErrorType {
    case Default
}
