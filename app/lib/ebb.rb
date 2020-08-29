class Ebb
  def initialize(speed: 1)
    @tick = 0
    @speed = speed
    @delays = {}
    @fps = {}
    @transitions = {}
  end

  def tick
    @tick += 1
  end

  ## Frames

  def frames(frames, fps = 60)
    i = (@tick / (60/fps)).round % frames.length

    result = frames[i]
    block_given? ? yield(result) : result
  end

  ## Shifts

  def delay(id, value, time)
    @delays[id] ||= Array.new(time - 1) { |_i| value }
    @delays[id].unshift value
    result = @delays[id].pop
    block_given? ? yield(result) : result
  end

  def fps(id, value, fps = 60)
    @fps[id] ||= value

    @fps[id] = value if @tick % (60 / fps) == 0

    result = @fps[id]
    block_given? ? yield(result) : result
  end

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

  ## Effects / Generators

  def blink(on = 60, off = nil)
    off ||= on
    period = off + on

    result = @tick % period < on
    block_given? ? yield(result) : result
  end

  def wave(min = -1, max = 1, rate = 120, f = :sin)
    rad = tick_rate_radians(rate)
    coefficient = (1 + Math.send(f, rad)) / 2

    result = between(min, max, coefficient)
    block_given? ? yield(result) : result
  end

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
