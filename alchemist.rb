require 'gosu'
# Alchemist's Apothecary - themed edition
# Amani Abdelrahim Elsayed | COS10009 Introduction to Programming
# CONSTANTS: screen IDs, property positions, moods and difficulty levels.
module GameScreen
  MENU = 0
  INSTRUCTIONS = 1
  SHOP = 2
  BREWING = 3
  RESULTS = 4
  WORKSHOP = 5
end
module PropertyType
  HEAT = 0
  CALM = 1
  ENERGY = 2
  BITTERNESS = 3
end
module CustomerMood
  HAPPY = 0
  SATISFIED = 1
  DISAPPOINTED = 2
end
module Difficulty
  EASY = 1
  MEDIUM = 2
  HARD = 3
end
TOTAL_CUSTOMERS = 10
STARTING_GOLD = 100
WIN_SCORE = 80
PERFECT_BONUS = 15
PATIENCE_SECONDS = [0, 90, 60]
ROOT = __dir__
# DATA MODELS: record-like classes keep related game values together.
class Ingredient
  attr_accessor :name, :heat, :calm, :energy, :bitterness,
                :colour, :cost, :min_reputation
end
class Customer
  attr_accessor :name, :request_text, :target_heat, :target_calm,
                :target_energy, :target_bitterness, :base_payment,
                :min_reputation, :difficulty, :image_name
end
class Potion
  attr_accessor :properties, :colour, :ingredient_count
  def initialize
    @properties = [0, 0, 0, 0]
    @colour = Gosu::Color.rgb(45, 45, 55)
    @ingredient_count = 0
  end
end
class Result
  attr_accessor :match_score, :payment, :reputation_change, :mood, :timed_out
end
class Player
  attr_accessor :gold, :reputation, :customers_served, :inventory
end
class GameData
  attr_accessor :screen, :ingredients, :customers, :cauldron, :potion,
                :current_customer, :result, :player, :message, :scores,
                :seen_customers
end
class GuideLine
  attr_accessor :key, :text, :sample
end
# DATA LOADING: a count is followed by fields on separate lines.
def read_field(file)
  value = file.gets
  abort('A data record is incomplete.') if value.nil?
  value.chomp
end

def load_records(filename)
  path = File.join(ROOT, filename)
  abort("Missing data file: #{filename}") unless File.exist?(path)
  File.open(path) { |file| Array.new(read_field(file).to_i) { yield file } }
end

# Ingredient records hold the four potion properties, RGB colour, price and unlock.
def load_ingredients(filename)
  load_records(filename) do |file|
    ingredient = Ingredient.new
    ingredient.name = read_field(file)
    ingredient.heat, ingredient.calm, ingredient.energy, ingredient.bitterness =
      Array.new(4) { read_field(file).to_i }
    ingredient.colour = Gosu::Color.rgb(*Array.new(3) { read_field(file).to_i })
    ingredient.cost = read_field(file).to_i
    ingredient.min_reputation = read_field(file).to_i
    ingredient
  end
end

# Customer records describe their request, targets, payment, difficulty and image.
def load_customers(filename)
  load_records(filename) do |file|
    customer = Customer.new
    customer.name = read_field(file)
    customer.request_text = read_field(file)
    customer.target_heat, customer.target_calm, customer.target_energy, customer.target_bitterness =
      Array.new(4) { read_field(file).to_i }
    customer.base_payment = read_field(file).to_i
    customer.min_reputation = read_field(file).to_i
    customer.difficulty = read_field(file).to_i
    customer.image_name = read_field(file)
    customer
  end
end

# Three levels share the same brewing logic.
def get_level(customers_served)
  return Difficulty::EASY if customers_served < 3
  return Difficulty::MEDIUM if customers_served < 6
  return Difficulty::HARD
end
def get_level_name(level)
  ['Apprentice', 'Skilled', 'Master'][level - 1]
end
def minimum_ingredients(level)
  level + 1
end
def get_available_customers(customers, reputation, level)
  customers.select do |customer|
    customer.min_reputation <= reputation && customer.difficulty == level
  end
end
# Choose an unserved customer before repeating any orders.
def choose_next_customer(game)
  level = get_level(game.player.customers_served)
  available = get_available_customers(game.customers, game.player.reputation, level)
  if available.empty?
    game.current_customer = nil
    game.message = 'No customers are available.'
    return
  end
  choices = available.reject { |customer| game.seen_customers.include?(customer.name) }
  if choices.empty?
    game.seen_customers = []
    choices = available.dup
  end
  choices.delete(game.current_customer) if choices.length > 1
  game.current_customer = choices[rand(choices.length)]
  game.seen_customers << game.current_customer.name
end
# Build a fresh game and give the player starting stock and gold.
def create_game_data
  game = GameData.new
  game.ingredients = load_ingredients('ingredients.txt')
  game.customers = load_customers('customers.txt')
  game.screen = GameScreen::MENU
  game.cauldron = []
  game.potion = Potion.new
  game.result = Result.new
  game.scores = []
  game.seen_customers = []
  player = Player.new
  player.gold = STARTING_GOLD
  player.reputation = 0
  player.customers_served = 0
  player.inventory = game.ingredients.map { |ingredient| ingredient.min_reputation == 0 ? 2 : 0 }
  game.player = player
  game.message = 'Welcome to the Apothecary!'
  choose_next_customer(game)
  return game
end
# Stock management. Return true only when an action succeeds.
def update_inventory(player, index, amount)
  player.inventory[index] += amount
end
def buy_ingredient(game, index)
  ingredient = game.ingredients[index]
  if game.player.reputation < ingredient.min_reputation
    game.message = 'This ingredient is locked.'
    return false
  elsif game.player.gold < ingredient.cost
    game.message = 'Not enough gold.'
    return false
  end
  game.player.gold -= ingredient.cost
  update_inventory(game.player, index, 1)
  game.message = "Purchased #{ingredient.name}."
  return true
end
# Potion properties and colour are calculated by averaging the ingredients.
def blend_colour(ingredients, cauldron)
  return Gosu::Color.rgb(45, 45, 55) if cauldron.empty?
  # Each RGB channel is averaged independently.
  colours = cauldron.map { |index| ingredients[index].colour }
  count = colours.length
  Gosu::Color.rgb(colours.sum(&:red) / count, colours.sum(&:green) / count,
                  colours.sum(&:blue) / count)
end
def mix_ingredients(ingredients, cauldron)
  potion = Potion.new
  return potion if cauldron.empty?
  # Average all four attributes to form the new potion.
  attributes = [:heat, :calm, :energy, :bitterness]
  count = cauldron.length
  potion.properties = attributes.map do |attribute|
    (cauldron.sum { |index| ingredients[index].public_send(attribute) }.to_f / count).round
  end
  potion.colour = blend_colour(ingredients, cauldron)
  potion.ingredient_count = count
  return potion
end
# Move an owned ingredient to the cauldron and update the mixed potion.
def add_to_cauldron(game, index)
  if game.player.inventory[index] <= 0
    game.message = 'This ingredient is out of stock.'
    return false
  end
  game.cauldron << index
  update_inventory(game.player, index, -1)
  game.potion = mix_ingredients(game.ingredients, game.cauldron)
  game.message = "#{game.ingredients[index].name} added."
  return true
end
# Return unused ingredients to the inventory before resetting the potion.
def clear_cauldron(game)
  game.cauldron.each { |index| update_inventory(game.player, index, 1) }
  game.cauldron = []
  game.potion = Potion.new
  game.message = 'Cauldron cleared. Ingredients returned.'
end
# Calculate the original match score and rewards.
def get_customer_targets(customer)
  [customer.target_heat, customer.target_calm,
   customer.target_energy, customer.target_bitterness]
end
def calculate_match_score(potion, customer)
  targets = get_customer_targets(customer)
  difference = targets.each_with_index.sum do |target, index|
    (potion.properties[index] - target).abs
  end
  score = (100 - difference * 2.5).round
  [score, 0].max
end
def determine_mood(score)
  return CustomerMood::HAPPY if score >= 80
  return CustomerMood::SATISFIED if score >= 50
  return CustomerMood::DISAPPOINTED
end
def get_mood_name(mood)
  ['HAPPY', 'SATISFIED', 'DISAPPOINTED'][mood]
end
def calculate_payment(score, customer)
  bonus = score == 100 ? PERFECT_BONUS : 0
  (customer.base_payment * score / 100.0).round + bonus
end
# Read and write only the best completed average to a local text file.
def load_high_score
  path = File.join(ROOT, "high_score.txt")
  return 0 unless File.exist?(path)
  return [[File.read(path).to_i, 0].max, 100].min
rescue SystemCallError
  return 0
end
def save_high_score(score)
  File.write(File.join(ROOT, "high_score.txt"), score.to_s + "\n")
  return true
rescue SystemCallError
  return false
end
def calculate_average_score(scores)
  return 0 if scores.empty?
  return (scores.sum.to_f / scores.length).round
end
def check_game_end(game)
  game.player.customers_served >= TOTAL_CUSTOMERS
end
# Validate the recipe, calculate rewards and advance one customer order.
def serve_potion(game, timed_out = false)
  return false if game.current_customer.nil? || check_game_end(game) || game.screen == GameScreen::RESULTS
  required = minimum_ingredients(get_level(game.player.customers_served))
  if !timed_out && game.cauldron.empty?
    game.message = 'Your cauldron is empty.'
    return false
  elsif !timed_out && game.cauldron.length < required
    game.message = "You need at least #{required} ingredients."
    return false
  end
  result = Result.new
  result.timed_out = timed_out
  result.match_score = timed_out ? 0 : calculate_match_score(game.potion, game.current_customer)
  result.mood = determine_mood(result.match_score)
  result.payment = calculate_payment(result.match_score, game.current_customer)
  change = [1, 0, -1][result.mood]
  old_reputation = game.player.reputation
  game.player.reputation = [old_reputation + change, 0].max
  result.reputation_change = game.player.reputation - old_reputation
  game.player.gold += result.payment
  game.player.customers_served += 1
  game.scores << result.match_score
  game.result = result
  game.cauldron = []
  game.screen = GameScreen::RESULTS
  game.message = timed_out ? 'Time expired! Customer left; no payment.' : 'Potion served successfully.'
  return true
end
# GAME WINDOW: Gosu handles presentation, input, sounds and animation.
class AlchemistApp < Gosu::Window
  WIDTH = 1200
  HEIGHT = 800
  WHITE = Gosu::Color::WHITE
  GOLD = Gosu::Color.rgb(255, 210, 121)
  PANEL = Gosu::Color.rgba(9, 18, 34, 204)
  GREY = Gosu::Color.rgb(66, 76, 94)
  BLUE = Gosu::Color.rgb(39, 86, 145)
  GREEN = Gosu::Color.rgb(30, 108, 89)
  RED = Gosu::Color.rgb(150, 49, 68)
  PURPLE = Gosu::Color.rgb(94, 66, 147)
  GOOD = Gosu::Color.rgb(134, 235, 171)
  BAD = Gosu::Color.rgb(255, 129, 135)
  def initialize
    super(WIDTH, HEIGHT)
    self.caption = "Alchemist's Apothecary"
    @title_font = Gosu::Font.new(43)
    @heading_font = Gosu::Font.new(26)
    @font = Gosu::Font.new(21)
    @small_font = Gosu::Font.new(17)
    @guide_font = Gosu::Font.new(15)
    @score_font = Gosu::Font.new(75)
    @animation = 0
    @music_muted = false
    @effects_muted = false
    @high_score = load_high_score
    return_to_menu
    load_media
    @music.volume = 0.22
    @music.play(true)
  end
  def needs_cursor?
    return true
  end
  # All images are loaded once; the arrays use the level or mood index.
  def image_asset(folder, filename)
    return Gosu::Image.new(File.join(ROOT, 'assets', folder, filename))
  end
  def load_media
    @backgrounds = []
    @mentor_images = []
    @reaction_images = []
    @mentor_names = ['Witch', 'Night Witch', 'Fire Wizard']
    3.times do |index|
      @backgrounds << image_asset('backgrounds', "level#{index + 1}.jpg")
      @mentor_images << image_asset('characters', ['witch.png', 'night_witch.png', 'red_wizard.png'][index])
      @reaction_images << image_asset('characters', ['happy_emote.png', 'wizard.png', 'angry_wizard.png'][index])
    end
    @menu_background = image_asset('backgrounds', 'menu.jpg')
    @shop_background = image_asset('backgrounds', 'shop.jpg')
    @star_image = image_asset('characters', 'star.png')
    @customer_images = @game.customers.map do |customer|
      image_asset('characters', customer.image_name + '.png')
    end
    @sound_names = ['click', 'coin', 'splash', 'success', 'error', 'level_up']
    @sounds = @sound_names.map do |name|
      Gosu::Sample.new(File.join(ROOT, 'sounds', name + '.wav'))
    end
    @music = Gosu::Song.new(File.join(ROOT, 'sounds', 'background.wav'))
    # Read each subtitle and load its corresponding voice recording.
    @guide_lines = load_records('guide.txt') do |file|
      line = GuideLine.new
      line.key = read_field(file)
      line.text = read_field(file)
      line.sample = Gosu::Sample.new(File.join(ROOT, 'sounds', 'voices', line.key + '.wav'))
      line
    end
  end

  # Play short sound effects independently of the looping music.
  def play_sound(name)
    return if @effects_muted
    index = @sound_names.index(name)
    @sounds[index].play(0.45) unless index.nil?
  end
  # Keep one guide voice channel so recordings cannot overlap.
  def stop_voice
    @speech.stop unless @speech.nil?
    @speech = nil
  end
  def speaking?
    return !@speech.nil? && @speech.playing?
  end
  def replay_voice
    stop_voice
    @speech = @guide_line.sample.play(0.9) if !@guide_line.nil? && !@effects_muted
  end
  def say(key)
    @guide_line = @guide_lines.find { |line| line.key == key }
    replay_voice
  end
  def toggle_audio
    muted = !(@music_muted && @effects_muted)
    @music_muted = @effects_muted = muted
    stop_voice if muted
  end
  def handle_audio_click(mx, my)
    if clicked?(mx, my, 862, 30, 146, 37)
      @music_muted = !@music_muted
    elsif clicked?(mx, my, 1018, 30, 146, 37)
      @effects_muted = !@effects_muted
      stop_voice if @effects_muted
    else
      return false
    end
    return true
  end
  # Use real elapsed milliseconds to update countdowns and timeout results.
  def remaining_seconds
    return [(@deadline - Gosu.milliseconds + 999) / 1000, 0].max
  end
  def update
    @animation = (@animation + 1) % 120
    @reaction_alpha = [255, @reaction_alpha + 9].min if @game.screen == GameScreen::RESULTS
    # Duck background music while a guide speaks.
    @music.volume = @music_muted ? 0 : (speaking? ? 0.07 : 0.22)
    finish_potion(@game, true) if @deadline && Gosu.milliseconds >= @deadline
  end
  def current_level(game)
    round = game.player.customers_served
    round -= 1 if game.screen == GameScreen::RESULTS
    return get_level(round)
  end
  def level_colour(game)
    return [BLUE, GREEN, RED][current_level(game) - 1]
  end
  # Automatic narration is limited to the first order and new levels.
  def shop_voice(game)
    stop_voice
    @guide_line = nil
    served = game.player.customers_served
    say("welcome_#{game.current_customer.image_name}") if served == 0
    say("welcome_#{current_level(game)}") if served == 3 || served == 6
  end
  def start_new_game
    return_to_menu
    @game.screen = GameScreen::WORKSHOP
    shop_voice(@game) unless @game.current_customer.nil?
  end
  # Start a timed order only once, even if the player returns to the shop.
  def start_brewing(game)
    return if game.current_customer.nil?
    stop_voice
    @guide_line = @paid_help
    game.screen = GameScreen::BREWING
    seconds = PATIENCE_SECONDS[current_level(game) - 1]
    @deadline ||= Gosu.milliseconds + seconds * 1000 if seconds > 0
    game.message = 'Compare your potion with the target.'
    if game.player.customers_served == 0 && !@first_brew_explained
      @first_brew_explained = true
      say("brew_#{game.current_customer.image_name}")
    end
  end
  # A recipe is purchased once per order, then remains available for free.
  def buy_help(game)
    return if game.current_customer.nil?
    if @paid_help
      @guide_line = @paid_help
      replay_voice
    elsif game.player.gold < 100
      game.message = 'You need 100 gold to buy a recipe.'
      play_sound('error')
    else
      game.player.gold -= 100
      say("help_#{game.customers.index(game.current_customer)}")
      @paid_help = @guide_line
      game.message = 'Recipe unlocked for this order. Ingredient costs are separate.'
      play_sound('coin')
    end
  end
  # Handle successful serving or timeout, then play the matching feedback.
  def finish_potion(game, timed_out = false)
    timed_out = timed_out || (!@deadline.nil? && Gosu.milliseconds >= @deadline)
    unless serve_potion(game, timed_out)
      play_sound('error')
      return
    end
    stop_voice
    @guide_line = nil
    @paid_help = nil
    @reaction_alpha = 0
    @deadline = nil
    if check_game_end(game)
      average = calculate_average_score(game.scores)
      if average > @high_score
        @high_score = average
        game.message = "New high score!" unless timed_out
        game.message = "High score could not be saved." unless save_high_score(average)
      end
      play_sound(average >= WIN_SCORE ? 'level_up' : 'error')
    elsif timed_out
      play_sound('error')
    elsif get_level(game.player.customers_served) > current_level(game)
      play_sound('level_up')
    else
      play_sound(['success', 'click', 'error'][game.result.mood])
    end
    # React once, with the mentor of the order just completed, not the next level.
    reaction = 'perfect' if game.result.match_score == 100
    reaction ||= 'happy' if game.result.mood == CustomerMood::HAPPY
    reaction ||= 'disappointed' if game.result.mood == CustomerMood::DISAPPOINTED
    say("#{reaction}_#{current_level(game)}") unless reaction.nil?
  end
  def next_customer(game)
    game.potion = Potion.new
    game.screen = GameScreen::WORKSHOP
    game.message = 'Prepare for your next customer.'
    @ingredient_page = 0
    choose_next_customer(game)
    shop_voice(game) unless game.current_customer.nil?
  end
  # DRAWING HELPERS: text, cards, buttons and sprites use shared styles.
  def text(message, x, y, colour = WHITE, font = @font)
    font.draw_text(message, x, y, 5, 1, 1, colour)
  end
  def centre(message, x, width, y, colour = WHITE, font = @font)
    text(message, x + (width - font.text_width(message)) / 2.0, y, colour, font)
  end
  def wrap_text(message, x, y, width, font = @small_font, colour = WHITE)
    words = message.split(' ')
    line = ''
    words.each do |word|
      candidate = line.empty? ? word : line + ' ' + word
      if !line.empty? && font.text_width(candidate) > width
        text(line, x, y, colour, font)
        y += font.height + 5
        line = word
      else
        line = candidate
      end
    end
    text(line, x, y, colour, font) unless line.empty?
  end
  def panel(x, y, width, height)
    Gosu.draw_rect(x, y, width, height, PANEL, 0)
    Gosu.draw_rect(x, y, width, 2, GOLD, 1)
    Gosu.draw_rect(x, y + height - 2, width, 2, GOLD, 1)
    Gosu.draw_rect(x, y, 2, height, GOLD, 1)
    Gosu.draw_rect(x + width - 2, y, 2, height, GOLD, 1)
  end
  def clicked?(mx, my, x, y, width, height)
    return mx >= x && mx < x + width && my >= y && my < y + height
  end
  def navigation_click?(mx, my, x, y, width, height)
    return false unless clicked?(mx, my, x, y, width, height)
    play_sound('click')
    return true
  end
  def button(x, y, width, height, label, colour = BLUE)
    border = clicked?(mouse_x, mouse_y, x, y, width, height) ? WHITE : GOLD
    Gosu.draw_rect(x, y, width, height, border, 3)
    Gosu.draw_rect(x + 2, y + 2, width - 4, height - 4, colour, 4)
    centre(label, x, width, y + (height - @font.height) / 2.0)
  end
  # Fit any sprite inside a rectangle without stretching it.
  def sprite(image, x, y, width, height, alpha = 255)
    scale = [width.to_f / image.width, height.to_f / image.height].min
    left = x + (width - image.width * scale) / 2.0
    top = y + (height - image.height * scale) / 2.0
    tint = Gosu::Color.rgba(255, 255, 255, alpha)
    image.draw(left, top, 2, scale, scale, tint)
  end
  # Choose the correct level scenery and draw player status.
  def draw_background(game)
    background = @backgrounds[current_level(game) - 1]
    background = @menu_background if game.screen == GameScreen::MENU || game.screen == GameScreen::INSTRUCTIONS
    background = @shop_background if game.screen == GameScreen::SHOP
    background.draw(0, 0, -3, WIDTH.to_f / background.width, HEIGHT.to_f / background.height)
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.rgba(5, 10, 25, 75), -2)
  end
  def draw_header(game)
    panel(20, 18, 1160, 96)
    text("Alchemist's Apothecary", 36, 28, GOLD, @heading_font)
    text("Gold: #{game.player.gold}", 38, 66, GOLD)
    text("Reputation: #{game.player.reputation}", 213, 66)
    round = game.player.customers_served + 1
    round -= 1 if game.screen == GameScreen::RESULTS
    text("Customer: #{round}/#{TOTAL_CUSTOMERS}", 434, 66)
    level = current_level(game)
    text("Level #{level} - #{get_level_name(level)}", 674, 65, GOLD)
    draw_audio_buttons
    if @deadline
      text("Time: #{remaining_seconds}s", 1000, 72, remaining_seconds <= 15 ? BAD : GOLD, @small_font)
    elsif (game.screen == GameScreen::SHOP || game.screen == GameScreen::WORKSHOP) && level > 1
      text("Ready: #{PATIENCE_SECONDS[level - 1]}s", 1000, 72, GOLD, @small_font)
    end
    Gosu.draw_rect(36, 99, 1128, 5, GREY, 3)
    progress = game.player.customers_served.to_f / TOTAL_CUSTOMERS
    Gosu.draw_rect(36, 99, 1128 * progress, 5, level_colour(game), 4)
  end
  def draw_audio_buttons
    button(862, 30, 146, 37, @music_muted ? "Music: OFF" : "Music: ON", GREY)
    button(1018, 30, 146, 37, @effects_muted ? "SFX: OFF" : "SFX: ON", GREY)
  end
  def draw_message(game)
    panel(20, 742, 1160, 40)
    text(game.message, 36, 752, GOLD, @small_font)
    text('F11: Fullscreen | M: Sound | R: Restart | Esc: Exit', 744, 752, WHITE, @small_font)
  end
  # Draw the mentor, current subtitle and recipe-help button.
  def draw_guide(game, tutorial = false)
    panel(20, 130, 255, 596)
    level = tutorial ? 1 : current_level(game)
    centre(@mentor_names[level - 1], 20, 255, 143, GOLD, @heading_font)
    centre('YOUR GUIDE', 20, 255, 177, WHITE, @small_font)
    bob = speaking? ? (12 - ((@animation % 48) - 24).abs / 2) : 0
    sprite(@mentor_images[level - 1], 34, 202 - bob, 227, 236)
    Gosu.draw_rect(35, 450, 225, 2, GOLD, 3)
    centre(speaking? ? 'Speaking...' : 'Your guide', 20, 255, 460, GOLD, @small_font)
    wrap_text(@guide_line.text, 37, 481, 220, @guide_font) if @guide_line
    if [GameScreen::SHOP, GameScreen::BREWING, GameScreen::WORKSHOP].include?(game.screen)
      button(40, 674, 215, 36, @paid_help ? 'Replay Recipe' : 'Help - 100 gold', PURPLE)
    elsif tutorial
      button(40, 674, 215, 36, 'Replay Voice', PURPLE)
    end
  end
  # Decorative cauldron, with live blended colour and frame-based bubbles.
  def draw_cauldron(x, y, colour, active, scale = 1.0)
    body = Gosu::Color.rgb(48, 54, 70)
    rim = Gosu::Color.rgb(121, 139, 165)
    Gosu.draw_rect(x - 145 * scale, y + 13 * scale, 40 * scale, 24 * scale, rim, 2)
    Gosu.draw_rect(x + 105 * scale, y + 13 * scale, 40 * scale, 24 * scale, rim, 2)
    Gosu.draw_rect(x - 73 * scale, y + 103 * scale, 28 * scale, 20 * scale, rim, 2)
    Gosu.draw_rect(x + 45 * scale, y + 103 * scale, 28 * scale, 20 * scale, rim, 2)
    Gosu.draw_quad(x - 110 * scale, y, body, x + 110 * scale, y, body,
                  x + 77 * scale, y + 106 * scale, body,
                  x - 77 * scale, y + 106 * scale, body, 3)
    Gosu.draw_rect(x - 120 * scale, y - 9 * scale, 240 * scale, 28 * scale, rim, 3)
    Gosu.draw_rect(x - 110 * scale, y - 3 * scale, 220 * scale, 17 * scale, colour, 4)
    return unless active
    5.times do |index|
      offset = (@animation + index * 15) % 60
      size = (7 + index % 3 * 3) * scale
      Gosu.draw_rect(x + (-80 + index * 39) * scale, y - (15 + offset) * scale, size, size, colour, 4)
    end
  end
  # Display the main menu and written instructions.
  def draw_menu
    panel(260, 72, 680, 660)
    centre("ALCHEMIST'S", 260, 680, 109, GOLD, @title_font)
    centre('APOTHECARY', 260, 680, 160, GOLD, @title_font)
    centre('The royal potion workshop', 260, 680, 220, WHITE, @heading_font)
    sprite(@mentor_images[0], 35, 285, 210, 385)
    sprite(@mentor_images[2], 950, 285, 215, 385)
    draw_cauldron(600, 328, Gosu::Color.rgb(165, 85, 224), true, 0.90)
    button(440, 478, 320, 54, 'Play Game', BLUE)
    button(440, 548, 320, 54, 'How to Play', PURPLE)
    button(440, 618, 320, 54, 'Exit Game', GREY)
    centre("Best average: #{@high_score}% | F11: Fullscreen | M: All sound", 260, 680, 689, GOLD, @small_font)
    draw_audio_buttons
  end
  def draw_instructions(game)
    draw_guide(game, true)
    panel(292, 130, 888, 596)
    text('HOW TO PLAY', 320, 156, GOLD, @title_font)
    instructions = ['1. Buy ingredients from the shop or use your starting stock.',
                    '2. Return to the workbench and click Start Brewing.',
                    '3. Click ingredients to mix them in the cauldron.',
                    '4. Match the heat, calm, energy and bitterness targets.',
                    '5. Clear the cauldron to recover the unused ingredients.',
                    '6. Serve your potion to earn gold and reputation.',
                    '7. Complete ten customer orders to finish the game.']
    instructions.each_with_index do |instruction, index|
      text(instruction, 321, 223 + index * 41)
    end
    text('Level 1: 2 ingredients, no timer | Level 2: 3, 90s | Level 3: 4, 60s', 321, 516, GOLD, @small_font)
    text('Timer begins with brewing, even if you visit the shop.', 321, 545, WHITE, @small_font)
    text('Win with 80% average. Perfect potion: +15 gold. Help: 100 gold.', 321, 574, WHITE, @small_font)
    draw_audio_buttons
    button(555, 645, 350, 50, 'Back to Menu', PURPLE)
  end
  # Ingredient cards are shared by the shop and brewing screens.
  def ingredient_x(slot)
    return 310 + (slot % 2) * 220
  end
  def ingredient_y(slot)
    return 225 + (slot / 2) * 112
  end
  def draw_ingredient_cards(game, shopping)
    6.times do |slot|
      index = @ingredient_page * 6 + slot
      next if index >= game.ingredients.length
      ingredient = game.ingredients[index]
      quantity = game.player.inventory[index]
      x = ingredient_x(slot)
      y = ingredient_y(slot)
      locked = shopping && game.player.reputation < ingredient.min_reputation
      colour = locked || (!shopping && quantity == 0) ? GREY : level_colour(game)
      border = clicked?(mouse_x, mouse_y, x, y, 210, 100) ? WHITE : GOLD
      Gosu.draw_rect(x, y, 210, 100, border, 3)
      Gosu.draw_rect(x + 2, y + 2, 206, 96, colour, 4)
      Gosu.draw_rect(x + 15, y + 11, 14, 10, GOLD, 5)
      Gosu.draw_rect(x + 10, y + 21, 24, 39, ingredient.colour, 5)
      Gosu.draw_rect(x + 14, y + 25, 3, 25, WHITE, 5)
      text(ingredient.name, x + 43, y + 10)
      text("Owned: #{quantity}", x + 43, y + 39, WHITE, @small_font)
      if locked
        label = "Unlock: reputation #{ingredient.min_reputation}"
      elsif shopping
        label = "Buy: #{ingredient.cost} gold"
      elsif quantity == 0
        label = 'Out of stock'
      else
        label = 'Click to add'
      end
      text(label, x + 12, y + 73, WHITE, @small_font)
    end
    pages = (game.ingredients.length / 6.0).ceil
    return if pages <= 1
    button(310, 565, 115, 38, 'Previous', GREY)
    button(625, 565, 115, 38, 'Next', GREY)
    centre("Page #{@ingredient_page + 1}/#{pages}", 425, 200, 573)
  end
  def customer_sprite(game, x, y, width, height)
    index = game.customers.index(game.current_customer)
    sprite(@customer_images[index], x, y, width, height) unless index.nil?
  end
  # Draw the reusable inventory cards in the current area.
  def draw_workshop(game, shopping)
    draw_guide(game)
    panel(290, 130, 470, 596)
    panel(775, 130, 405, 596)
    text(shopping ? 'Ingredient Shop' : 'Brewing Ingredients', 310, 148, GOLD, @heading_font)
    text(shopping ? 'Click an ingredient to purchase it.' : 'Click ingredients to add them.', 310, 183, WHITE, @small_font)
    draw_ingredient_cards(game, shopping)
  end
  # The workbench is the home screen; the shop is now a separate room.
  def draw_workbench(game)
    draw_guide(game)
    panel(290, 130, 470, 596)
    panel(775, 130, 405, 596)
    text('ALCHEMY WORKBENCH', 310, 151, GOLD, @heading_font)
    text('Shop for stock, then brew the customer order.', 310, 191, WHITE, @small_font)
    draw_cauldron(520, 349, Gosu::Color.rgb(175, 74, 190), true)
    button(310, 580, 210, 65, 'Visit Shop', GREEN)
    button(530, 580, 210, 65, 'Start Brewing', level_colour(game))
    return if game.current_customer.nil?
    customer = game.current_customer
    centre(customer.name, 775, 405, 147, GOLD, @heading_font)
    customer_sprite(game, 798, 207, 355, 270)
    wrap_text(customer.request_text, 798, 501, 350, @font)
    text("Minimum ingredients: #{minimum_ingredients(current_level(game))}", 798, 576, GOLD)
    level = current_level(game)
    text(level == 1 ? 'No timer this level' : "Time available: #{PATIENCE_SECONDS[level - 1]}s", 798, 614)
  end
  # Shop uses a different room/background and a return button.
  def draw_shop(game)
    draw_workshop(game, true)
    centre('THE ROYAL INGREDIENT SHOP', 290, 470, 641, GOLD)
    customer = game.current_customer
    return if customer.nil?
    centre('STOCK FOR YOUR ORDER', 775, 405, 147, GOLD, @heading_font)
    centre(customer.name, 775, 405, 188)
    customer_sprite(game, 797, 219, 360, 250)
    wrap_text(customer.request_text, 799, 486, 355, @font)
    text("Gold: #{game.player.gold}", 799, 555, GOLD)
    text('Buy items by clicking the ingredient cards.', 799, 589, WHITE, @small_font)
    button(799, 641, 357, 58, @shop_return_screen == GameScreen::BREWING ? 'Return to Brewing' : 'Return to Workbench', GREEN)
  end
  # Compare current potion values against the requested customer targets.
  def draw_properties(game)
    names = ['Heat', 'Calm', 'Energy', 'Bitterness']
    targets = get_customer_targets(game.current_customer)
    text('Property', 800, 461, GOLD, @small_font)
    text('Potion', 958, 461, GOLD, @small_font)
    text('Target', 1082, 461, GOLD, @small_font)
    names.each_with_index do |name, index|
      y = 493 + index * 37
      value = game.potion.properties[index]
      colour = game.potion.ingredient_count > 0 && value == targets[index] ? GOOD : WHITE
      text(name, 800, y)
      centre(value.to_s, 944, 85, y, colour)
      centre(targets[index].to_s, 1064, 85, y)
    end
  end
  def draw_brewing(game)
    draw_workshop(game, false)
    return if game.current_customer.nil?
    text(game.current_customer.name, 800, 148, GOLD, @heading_font)
    wrap_text(game.current_customer.request_text, 800, 185, 355)
    customer_sprite(game, 789, 233, 122, 178)
    potion = game.potion
    draw_cauldron(1032, 326, potion.colour, potion.ingredient_count > 0, 0.78)
    required = minimum_ingredients(current_level(game))
    text("Ingredients: #{potion.ingredient_count} / Min #{required}", 800, 425, GOLD)
    draw_properties(game)
    button(310, 645, 210, 54, 'Clear Cauldron', GREY)
    button(530, 645, 210, 54, 'Visit Shop', PURPLE)
    button(799, 645, 357, 54, 'Serve Potion', level_colour(game))
  end
  # Show match percentage, rewards, stars and the final win/loss outcome.
  def draw_results(game)
    draw_guide(game)
    panel(290, 130, 570, 596)
    panel(875, 130, 305, 596)
    result = game.result
    colour = [GOOD, GOLD, BAD][result.mood]
    centre('POTION RESULTS', 290, 570, 151, GOLD, @heading_font)
    centre(game.current_customer.name, 290, 570, 188)
    centre("#{result.match_score}%", 290, 570, 229, colour, @score_font)
    Gosu.draw_rect(330, 330, 490, 18, GREY, 3)
    Gosu.draw_rect(330, 330, 490 * result.match_score / 100.0, 18, colour, 4)
    centre("Customer mood: #{get_mood_name(result.mood)}", 290, 570, 365, colour)
    bonus = result.match_score == 100 ? ' (includes +15 bonus)' : ''
    centre("Gold earned: +#{result.payment}#{bonus}", 290, 570, 406, GOLD)
    centre("Reputation change: #{result.reputation_change}", 290, 570, 444)
    centre('CUSTOMER REACTION', 875, 305, 151, GOLD, @heading_font)
    sprite(@reaction_images[result.mood], 893, 217, 269, 370, @reaction_alpha)
    stars = 3 - result.mood
    # Draw one small transparent gold star for each earned rating point.
    stars.times do |index|
      sprite(@star_image, 1027 - stars * 16 + index * 32, 589, 28, 28)
    end
    centre("#{stars}/3 stars", 875, 305, 621, GOLD)
    centre(result.timed_out ? 'TIME EXPIRED' : get_mood_name(result.mood), 875, 305, 653, colour, @heading_font)
    if check_game_end(game)
      average = calculate_average_score(game.scores)
      won = average >= WIN_SCORE
      centre(won ? 'YOU WIN!' : 'YOU LOSE - TARGET 80%', 290, 570, 489, won ? GOOD : BAD, @heading_font)
      centre("Final gold: #{game.player.gold} | Reputation: #{game.player.reputation}", 290, 570, 530)
      centre("Average: #{average}% | Best: #{@high_score}%", 290, 570, 568, GOLD)
      button(310, 645, 260, 54, 'Play Again', GREEN)
      button(580, 645, 260, 54, 'Main Menu', PURPLE)
    else
      centre("Customers served: #{game.player.customers_served}/10", 290, 570, 511)
      next_level = get_level(game.player.customers_served)
      centre("LEVEL #{next_level} UNLOCKED!", 290, 570, 555, GOLD, @heading_font) if next_level > current_level(game)
      button(375, 645, 400, 54, 'Next Customer', level_colour(game))
    end
  end
  # INPUT HELPERS: map ingredient cards and page controls to player actions.
  def handle_ingredient_click(game, mx, my)
    6.times do |slot|
      index = @ingredient_page * 6 + slot
      next unless index < game.ingredients.length && clicked?(mx, my, ingredient_x(slot), ingredient_y(slot), 210, 100)
      if game.screen == GameScreen::SHOP
        play_sound(buy_ingredient(game, index) ? 'coin' : 'error')
      else
        play_sound(add_to_cauldron(game, index) ? 'splash' : 'error')
      end
      return true
    end
    return false
  end
  def handle_page_click(game, mx, my)
    pages = (game.ingredients.length / 6.0).ceil
    if pages > 1 && clicked?(mx, my, 310, 565, 115, 38) && @ingredient_page > 0
      @ingredient_page -= 1
      play_sound('click')
    elsif pages > 1 && clicked?(mx, my, 625, 565, 115, 38) && @ingredient_page < pages - 1
      @ingredient_page += 1
      play_sound('click')
    end
  end
  # Reset transient state without changing sound preferences or the record.
  def return_to_menu
    @deadline = nil
    stop_voice
    @guide_line = nil
    @paid_help = nil
    @game = create_game_data
    @ingredient_page = 0
    @reaction_alpha = 0
    @first_brew_explained = false
    @shop_return_screen = GameScreen::WORKSHOP
  end
  # Route mouse input according to the screen currently displayed.
  def handle_click(game, mx, my)
    return if handle_audio_click(mx, my)
    if @deadline && Gosu.milliseconds >= @deadline
      finish_potion(game, true)
      return
    end
    if [GameScreen::SHOP, GameScreen::BREWING, GameScreen::WORKSHOP].include?(game.screen)
      return buy_help(game) if clicked?(mx, my, 40, 674, 215, 36)
      if game.screen != GameScreen::WORKSHOP
        return if handle_ingredient_click(game, mx, my)
        handle_page_click(game, mx, my)
      end
    elsif game.screen == GameScreen::INSTRUCTIONS && clicked?(mx, my, 40, 674, 215, 36)
      return replay_voice
    end
    case game.screen
    when GameScreen::MENU
      if navigation_click?(mx, my, 440, 478, 320, 54)
        start_new_game
      elsif navigation_click?(mx, my, 440, 548, 320, 54)
        game.screen = GameScreen::INSTRUCTIONS
        say('tutorial')
      elsif clicked?(mx, my, 440, 618, 320, 54)
        close
      end
    when GameScreen::INSTRUCTIONS
      if navigation_click?(mx, my, 555, 645, 350, 50)
        return_to_menu
      end
    when GameScreen::WORKSHOP
      if navigation_click?(mx, my, 310, 580, 210, 65)
        @shop_return_screen = GameScreen::WORKSHOP
        game.screen = GameScreen::SHOP
        stop_voice
      elsif navigation_click?(mx, my, 530, 580, 210, 65)
        start_brewing(game)
      end
    when GameScreen::SHOP
      if navigation_click?(mx, my, 799, 641, 357, 58)
        game.screen = @shop_return_screen
        game.message = 'Back at the alchemy workbench.'
      end
    when GameScreen::BREWING
      if clicked?(mx, my, 310, 645, 210, 54)
        clear_cauldron(game)
        play_sound('splash')
      elsif clicked?(mx, my, 530, 645, 210, 54)
        @shop_return_screen = GameScreen::BREWING
        game.screen = GameScreen::SHOP
        game.message = 'Visit the shop to buy more ingredients.'
        play_sound('click')
        stop_voice
      elsif clicked?(mx, my, 799, 645, 357, 54)
        finish_potion(game)
      end
    when GameScreen::RESULTS
      if check_game_end(game)
        start_new_game if navigation_click?(mx, my, 310, 645, 260, 54)
        return_to_menu if navigation_click?(mx, my, 580, 645, 260, 54)
      elsif navigation_click?(mx, my, 375, 645, 400, 54)
        next_customer(game)
      end
    end
  end
  def button_down(id)
    case id
    when Gosu::MS_LEFT
      handle_click(@game, mouse_x, mouse_y)
    when Gosu::KB_ESCAPE
      close
    when Gosu::KB_R
      return_to_menu
    when Gosu::KB_M
      toggle_audio
    when Gosu::KB_V
      replay_voice
    else
      super
    end
  end
  # Render only the active game screen each frame.
  def draw
    draw_background(@game)
    return draw_menu if @game.screen == GameScreen::MENU
    return draw_instructions(@game) if @game.screen == GameScreen::INSTRUCTIONS
    draw_header(@game)
    case @game.screen
    when GameScreen::WORKSHOP then draw_workbench(@game)
    when GameScreen::SHOP then draw_shop(@game)
    when GameScreen::BREWING then draw_brewing(@game)
    when GameScreen::RESULTS then draw_results(@game)
    end
    draw_message(@game)
  end
end
AlchemistApp.new.show if __FILE__ == $PROGRAM_NAME