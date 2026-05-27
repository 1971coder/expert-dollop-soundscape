import XCTest

@testable import Soundscape

final class RingBufferTests: XCTestCase {
    func testPushPopRoundTrip() {
        let buffer = ParameterRingBuffer(capacity: 16)
        XCTAssertTrue(buffer.tryPush(ParameterDelta(target: .masterGain, value: 0.5)))
        let popped = buffer.tryPop()
        XCTAssertEqual(popped?.target, .masterGain)
        XCTAssertEqual(popped?.value, 0.5)
    }

    func testEmptyReturnsNil() {
        let buffer = ParameterRingBuffer(capacity: 4)
        XCTAssertNil(buffer.tryPop())
    }

    func testFullRejectsFurtherPushes() {
        let buffer = ParameterRingBuffer(capacity: 4)
        for _ in 0..<4 {
            XCTAssertTrue(buffer.tryPush(ParameterDelta(target: .masterGain, value: 0)))
        }
        XCTAssertFalse(buffer.tryPush(ParameterDelta(target: .masterGain, value: 0)))
    }

    func testWrapAround() {
        let buffer = ParameterRingBuffer(capacity: 4)
        for index in 0..<10 {
            XCTAssertTrue(buffer.tryPush(ParameterDelta(target: .masterGain, value: Float(index))))
            XCTAssertEqual(buffer.tryPop()?.value, Float(index))
        }
    }

    func testConcurrentSPSCProducerConsumer() {
        let buffer = ParameterRingBuffer(capacity: 256)
        let messageCount = 10_000
        let producer = DispatchQueue(label: "ringbuffer.test.producer")
        let consumer = DispatchQueue(label: "ringbuffer.test.consumer")
        let consumed = NSMutableArray()
        let exp = expectation(description: "consumer drains all messages")

        consumer.async {
            var seen = 0
            while seen < messageCount {
                if let delta = buffer.tryPop() {
                    consumed.add(delta.value)
                    seen += 1
                }
            }
            exp.fulfill()
        }

        producer.async {
            for index in 0..<messageCount {
                while !buffer.tryPush(ParameterDelta(target: .masterGain, value: Float(index))) {
                    // spin until consumer drains a slot
                }
            }
        }

        wait(for: [exp], timeout: 10)
        XCTAssertEqual(consumed.count, messageCount)
        for index in 0..<messageCount {
            XCTAssertEqual(consumed[index] as? Float, Float(index), "out-of-order at \(index)")
        }
    }
}
