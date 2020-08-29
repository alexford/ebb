class Ebb

  # Constructor. Create one instance of Ebb to share across frames!
  #
  # @return [Ebb] an Ebb instance
  def initialize
    @tick = 0
    @delays = {}
    @fps = {}
    @transitions = {}
  end

  # Tick Ebb forward by one frame. Call this once per frame!
  def tick
    @tick += 1
  end

  # Loops through a given set of values, at given fps
  #
  # @param frames [Array, []] list of values to loop through. The values can be anything
  # @param fps [Integer] how quickly to rotate through frames, in fps
  # @return the value of the current frame
  def frames(frames, fps = 60)
    i = (@tick / (60/fps)).round % frames.length

    result = frames[i]
    block_given? ? yield(result) : result
  end

  # Delays a value by given time (frames)
  #
  # @param id A unique reference to this value. Symbols work well.
  # @param value The current, "live" value. This can be any type.
  # @param time [Integer] Length of delay in frames
  # @return The value from the given time in the past, or the initial value if enough time hasnt passed yet
  def delay(id, value, time)
    @delays[id] ||= Array.new(time - 1) { |_i| value }
    @delays[id].unshift value
    result = @delays[id].pop
    block_given? ? yield(result) : result
  end

  # Limits updates to a value to given fps
  #
  # @param id A unique reference to this value. Symbols work well.
  # @param value The current, "live" value. This can be any type.
  # @param fps [Integer] how often the returned value should be updated
  # @return The provided value, limited to given fps.
  def fps(id, value, fps = 60)
    @fps[id] ||= value

    @fps[id] = value if @tick % (60 / fps) == 0

    result = @fps[id]
    block_given? ? yield(result) : result
  end

  # Transition from one value to another
  #
  # Currently transitions linearly only.
  #
  # @param id A unique reference to this transition. Symbols work well.
  # @param from [Numeric] the initial value
  # @param to [Numeric] the final value
  # @param time [Integer] how many frames the transition should take
  # @param reset [Boolean] if true, restart the transition from the beginning
  # @return the current value. Will be between from and to values. "to" value will be returned if allotted time has passed since the last reset, this
  def transition(id, from = 0, to = 1, time = 60, reset = false)
    @transitions[id] = nil if reset
    @transitions[id] ||= [].tap do |a|
      (0..time).map do |i|
        a[@tick + i] = between(from, to, i/time)
      end
    end

    frames = @transitions[id]
    index = @tick.clamp(frames.index(from.to_f), frames.index(to.to_f))

    result = frames[index]
    block_given? ? yield(result) : result
  end

  # "Blink" a boolean on and off over time
  #
  # @param on [Integer] (frames) how long to blink "on"
  # @param off [Integer] (frames) how long to blink "off". Defaults to value of on
  # @return [Boolean] the state of the blink. on = true, off = false
  def blink(on = 60, off = nil)
    off ||= on
    period = off + on

    result = @tick % period < on
    block_given? ? yield(result) : result
  end

  # Alternate smoothly between a min and max value
  #
  # Similar to #bounce
  #
  # @param min [Numeric] The minimum value of the wave
  # @param max [Numeric] The maximum value of the wave
  # @param rate [Integer] (frames) time for one cycle (from min to max and back)
  # @param f [Symbol] Name of the wave function called on Math
  # @return [Float] the current value. Will be between min and max
  def wave(min = -1, max = 1, rate = 120, f = :sin)
    rad = tick_rate_radians(rate)
    coefficient = (1 + Math.send(f, rad)) / 2

    result = between(min, max, coefficient)
    block_given? ? yield(result) : result
  end

  # Alternate between a min and max value by bouncing off the min value
  #
  # Similar to #wave
  #
  # @param min [Numeric] The "bottom" value of the bounce
  # @param max [Numeric] The "top" value of the bounce
  # @param rate [Integer] (frames) time for one cycle (from min to max and back)
  # @return [Float] the current value. Will be between min and max
  def bounce(min = -1, max = 1, rate = 120)
    rad = tick_rate_radians(rate)
    coefficient = Math.sin(rad).abs

    result = between(min, max, coefficient)
    block_given? ? yield(result) : result
  end

  private

  def between(min, max, coefficient)
    min + coefficient * (max - min)
  end

  def tick_rate_radians(rate)
    # TODO: This seems overthought...
    ((@tick % rate) / rate * 360) * (3.14159 / 180)
  end
end
