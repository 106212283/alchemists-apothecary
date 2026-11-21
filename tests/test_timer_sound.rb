# Test countdown-tick selection without requiring Gosu graphics or speakers.
$LOADED_FEATURES << 'gosu.rb'
module Gosu
  class Color
    def self.rgb(*); new; end
    def self.rgba(*); new; end
    WHITE = new
  end
  class Window; end
  def self.milliseconds = @clock || 0
  def self.clock=(time); @clock = time; end
end
require_relative '../alchemist'
class FakeSample
  attr_reader :volumes
  def initialize = @volumes = []
  def play(volume) = @volumes << volume
end
app = AlchemistApp.allocate
normal, urgent = FakeSample.new, FakeSample.new
app.instance_variable_set(:@timer_sounds, [normal, urgent])
app.instance_variable_set(:@effects_muted, false)
app.instance_variable_set(:@deadline, 60_000)
app.instance_variable_set(:@last_tick_second, 60)
def check(label, value)
  raise "FAIL: #{label}" unless value
  puts "PASS: #{label}"
end
Gosu.clock = 1000
app.play_timer_tick
check('normal tick at 59 seconds', normal.volumes.size == 1)
app.play_timer_tick
check('no repeat within the same second', normal.volumes.size == 1)
Gosu.clock = 44_000
app.play_timer_tick
check('urgent double-click sample at 16 seconds? still normal', normal.volumes.size == 2)
Gosu.clock = 45_000
app.play_timer_tick
check('urgent tick starts at 15 seconds', urgent.volumes.size == 1)
check('urgent tick is louder', urgent.volumes[0] > normal.volumes[0])
app.instance_variable_set(:@effects_muted, true)
Gosu.clock = 46_000
app.play_timer_tick
check('SFX mute silences timer', urgent.volumes.size == 1)
app.instance_variable_set(:@effects_muted, false)
Gosu.clock = 60_000
app.play_timer_tick
check('timer silent at zero', urgent.volumes.size == 1)
app.instance_variable_set(:@deadline, nil)
app.play_timer_tick
check('untimed level is silent', urgent.volumes.size == 1)
