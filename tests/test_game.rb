# Headless game-logic tests: no Gosu window or audio device is required.
$LOADED_FEATURES << 'gosu.rb'
module Gosu
  class Color
    attr_reader :red, :green, :blue
    def initialize(r, g, b); @red, @green, @blue = r, g, b; end
    def self.rgb(r, g, b); new(r, g, b); end
    def self.rgba(r, g, b, a); new(r, g, b); end
    WHITE = rgb(255, 255, 255)
  end
  class Window; end
  MS_LEFT = 1
  KB_H = 2
  KB_D = 3
  KB_ESCAPE = 4
  KB_R = 5
  KB_M = 6
  KB_V = 7
  def self.milliseconds; 10_000; end
end
require_relative '../alchemist'

$checks = 0
def verify(message, condition)
  raise "FAILED: #{message}" unless condition
  $checks += 1
end

# Load the real text data, not fabricated customer records.
game = create_game_data
verify('6 ingredients loaded', game.ingredients.size == 6)
verify('10 customers loaded', game.customers.size == 10)
verify('starting gold', game.player.gold == 100)
verify('fresh history is empty', game.history.empty?)
verify('initial level one', get_level(0) == 1)
verify('level two at order four', get_level(3) == 2)
verify('level three at order seven', get_level(6) == 3)
verify('level ingredient minimums', [1,2,3].map { |level| minimum_ingredients(level) } == [2,3,4])
verify('patience settings', PATIENCE_SECONDS == [0,60,30])
verify('happy mood', determine_mood(80) == CustomerMood::HAPPY)
verify('satisfied mood', determine_mood(50) == CustomerMood::SATISFIED)
verify('disappointed mood', determine_mood(49) == CustomerMood::DISAPPOINTED)
verify('100 score bonus', calculate_payment(100, game.current_customer) == game.current_customer.base_payment + 15)
verify('no bonus for imperfect score', calculate_payment(99, game.current_customer) == (game.current_customer.base_payment * 0.99).round)
verify('no match less than zero', calculate_match_score(Potion.new, game.current_customer) >= 0)

# Check stock errors and successful movement to/from the cauldron.
game.player.gold = 0
verify('cannot buy without gold', !buy_ingredient(game, 0))
game.player.gold = 100
game.player.inventory[0] = 0
verify('cannot add unavailable ingredient', !add_to_cauldron(game, 0))
game.player.inventory[0] = 2
verify('can add stocked ingredient', add_to_cauldron(game, 0))
verify('stock reduced', game.player.inventory[0] == 1)
clear_cauldron(game)
verify('stock returned', game.player.inventory[0] == 2)
verify('cauldron emptied', game.cauldron.empty?)

# Serve an exact-match potion and verify the new record and snapshot.
game.screen = GameScreen::BREWING
game.cauldron = [0,1]
game.potion.properties = get_customer_targets(game.current_customer)
game.potion.ingredient_count = 2
name = game.current_customer.name
verify('perfect potion served', serve_potion(game))
verify('perfect match', game.result.match_score == 100)
verify('properties snapshot', game.result.properties == get_customer_targets(game.current_customer))
verify('one history record', game.history.size == 1)
verify('history name recorded', game.history[0][0] == name)
verify('history percentage recorded', game.history[0][1] == 100)
verify('history three stars', game.history[0][2] == 3)
verify('history paid correctly', game.history[0][3] == game.result.payment)
verify('no duplicate serving', !serve_potion(game))
verify('fresh game resets history', create_game_data.history.empty?)

# Timed-out orders have no potion snapshot, zero score and still appear in history.
timed = create_game_data
timed.screen = GameScreen::BREWING
verify('timeout can end an order', serve_potion(timed, true))
verify('timeout zero score', timed.result.match_score == 0)
verify('timeout no potion details', timed.result.properties.nil?)
verify('timeout logged', timed.history.size == 1 && timed.history[0][1] == 0)
verify('timeout one star', timed.history[0][2] == 1)
verify('timeout no gold', timed.result.payment == 0)
verify('empty score average', calculate_average_score([]) == 0)
verify('rounded average', calculate_average_score([100, 79]) == 90)
verify('win target', WIN_SCORE == 80)

# Check navigation state without opening a graphics window.
app = AlchemistApp.allocate
app.instance_variable_set(:@game, game)
app.instance_variable_set(:@review, nil)
app.define_singleton_method(:play_sound) { |_name| }
app.handle_click(game, 725, 45)
verify('history button opens history', app.instance_variable_get(:@review) == :history)
app.handle_click(game, 600, 685)
verify('return button closes history', app.instance_variable_get(:@review).nil?)
app.handle_click(game, 350, 606)
verify('results button opens breakdown', app.instance_variable_get(:@review) == :details)
app.button_down(Gosu::KB_H)
verify('history shortcut switches overlay', app.instance_variable_get(:@review) == :history)
app.button_down(Gosu::KB_D)
verify('details shortcut switches overlay', app.instance_variable_get(:@review) == :details)
puts "PASS: #{$checks} checks (data, scoring, inventory, history, timeout and review controls)"
