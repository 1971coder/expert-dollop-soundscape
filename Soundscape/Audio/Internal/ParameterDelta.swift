public struct ParameterDelta: Sendable {
    public let target: ParameterId
    public let value: Float
    public let rampMilliseconds: UInt32

    public init(target: ParameterId, value: Float, rampMilliseconds: UInt32 = 80) {
        self.target = target
        self.value = value
        self.rampMilliseconds = rampMilliseconds
    }
}
