
require 'app/lib/ebb.rb'

$gtk.reset

def tick args
  $e ||= Ebb.new

  $e.tick
  text_examples = []
  line_examples = []
  sprite_examples = []

  text_examples << "blink: #{$e.blink}"
  text_examples << "blink(10): #{$e.blink(10)}"
  text_examples << "blink(20, 60): #{$e.blink(20, 60)}"

  $e.blink(100) do |on|
    text_examples << "blink with a block: #{on ? 'on' : 'off'}"
  end

  ## All float examples are rounded
  text_examples << ""
  text_examples << "wave: #{'%.2f' % $e.wave}"
  text_examples << "wave(0, 100, 240): #{'%.0f' % $e.wave(0, 100, 500)}"
  text_examples << "wave(0, 100, 240, :cos): #{'%.0f' % $e.wave(0, 100, 500, :cos)}"
  text_examples << "bounce: #{'%.2f' % $e.bounce}"

  text_examples << ""
  text_examples << "5 frames @ 1fps: #{
    $e.frames([
      "frame one",
      "frame two",
      "frame three",
      "frame four",
      "frame five"
    ], 1)
  }"

  text_examples << "5 frames @ 5fps: #{
    $e.frames([
      "frame one",
      "frame two",
      "frame three",
      "frame four",
      "frame five"
    ], 5)
  }"

  text_examples << ""
  text_examples << "reset transitions with spacebar"
  reset = args.inputs.keyboard.key_down.space

  text_examples << "transition: #{'%.2f' % $e.transition(:foo, 0, 1, 60, reset)}"
  text_examples << "transition(0,100,100): #{'%.0f' % $e.transition(:foo_2, 0, 100, 100, reset)}"

  line_examples << ["wave(0,200)", $e.wave(0, 200)]

  bounce = $e.bounce(0, 200)
  line_examples << ["b = bounce(0,200)", bounce ]

  delayed_bounce = $e.delay(:bounce, bounce, 100)
  line_examples << ["delay(:bounce, b, 100)", delayed_bounce]

  $e.delay(:bounce_2, bounce, 50) do |delayed|
    line_examples << ["delay(:bounce_b, b, 50) do...", delayed]
  end

  line_examples << ["fps(:bounce, b, 5)", $e.fps(:bounce, bounce, 5)]

  ## Sprite/combined examples

  # Orbit
  orbit_target = args.render_target(:orbit)
  orbit_x = $e.wave(0, 85, 60, :sin)
  orbit_y = $e.wave(0, 85, 60, :cos)
  orbit_target.solids << [orbit_x + 5, orbit_y + 5, 5, 5]
  $e.delay(:orbit_follower, [orbit_x,orbit_y], 3) do |delayed_coordinates|
    dx, dy = delayed_coordinates

    orbit_target.solids << [dx + 5, dy + 5, 5, 5,
      # 3fps loop of colors
      *$e.frames([[255, 0, 0], [0, 255, 0], [0, 0, 255] ], 3)
    ]
  end
  sprite_examples << ["'orbit' w/ delayed follower", :orbit]

  # Wave shot
  wave_shot_target = args.render_target(:wave_shot)
  wave_x = $e.transition(:wave_shot, 0, 200, 120, reset)
  $e.transition(:wave_height, 95, 5, 120, reset) do |height|
    wave_y = $e.bounce(0, height, 60)
    wave_shot_target.solids << [wave_x, wave_y, 5, 5]
  end
  sprite_examples << ["'bounce' (space to reset)", :wave_shot]
3
  ### Render the examples

  line_examples.each_with_index do |example, i|
    args.outputs.solids << [ 500, 700 - i*60, example[1], 5, 20, 20, 20]
    args.outputs.labels << [ 500, 700 - i*60 - 3, example[0], 20, 20, 20]
  end

  text_examples.each_with_index do |example, i|
    args.outputs.labels << [ 10, 700 - i*20, example, 20, 20, 20]
  end

  sprite_examples.each_with_index do |example, i|
    args.outputs.borders << [ 950, 700 - (i+1)*200, 200, 100] 
    args.outputs.sprites << {
      x: 950,
      y: 700 - (i+1)*200,
      w: 200,
      h: 100,
      path: example[1],
      source_x: 0,
      source_y: 0,
      source_w: 200,
      source_h: 100
    }
    args.outputs.labels << [ 950, 700 - (i+1)*200 - 20, example[0], 20, 20, 20]
  end
end
