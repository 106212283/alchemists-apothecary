require 'gosu'

# Alchemist's Apothecary - themed edition
# Amani Abdelrahim Elsayed | COS10009 Introduction to Programming
# Main game data and procedures
module GameScreen
  MENU = 0
  INSTRUCTIONS = 1
  SHOP = 2
  BREWING = 3
  RESULTS = 4
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
ROOT = __dir__
# Composite data types (records)
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
  attr_accessor :match_score, :payment, :reputation_change, :mood
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
# Data files: count followed by the fields of each record.
def open_data(filename)
  path = File.join(ROOT, filename)
  abort("Missing data file: #{filename}") unless File.exist?(path)
  return File.new(path, 'r')
end
def read_field(file)
  line = file.gets
  abort('A data record is incomplete.') if line.nil?
  return line.chomp
end
def load_ingredients(filename)
  ingredients = []
  file = open_data(filename)
  count = read_field(file).to_i
  index = 0
  while index < count
    ingredient = Ingredient.new
    ingredient.name = read_field(file)
    ingredient.heat = read_field(file).to_i
    ingredient.calm = read_field(file).to_i
    ingredient.energy = read_field(file).to_i
    ingredient.bitterness = read_field(file).to_i
    red = read_field(file).to_i
    green = read_field(file).to_i
    blue = read_field(file).to_i
    ingredient.colour = Gosu::Color.rgb(red, green, blue)
    ingredient.cost = read_field(file).to_i
    ingredient.min_reputation = read_field(file).to_i
    ingredients << ingredient
    index += 1
  end
  file.close
  return ingredients
end
def load_customers(filename)
  customers = []
  file = open_data(filename)
  count = read_field(file).to_i
  index = 0
  while index < count
    customer = Customer.new
    customer.name = read_field(file)
    customer.request_text = read_field(file)
    customer.target_heat = read_field(file).to_i
    customer.target_calm = read_field(file).to_i
    customer.target_energy = read_field(file).to_i
    customer.target_bitterness = read_field(file).to_i
    customer.base_payment = read_field(file).to_i
    customer.min_reputation = read_field(file).to_i
    customer.difficulty = read_field(file).to_i
    customer.image_name = read_field(file)
    customers << customer
    index += 1
  end
  file.close
  return customers
end
# Three levels share the same brewing logic.
def get_level(customers_served)
  if customers_served < 3
    return Difficulty::EASY
  elsif customers_served < 6
    return Difficulty::MEDIUM
  else
    return Difficulty::HARD
  end
end
def get_level_name(level)
  return ['Apprentice', 'Skilled', 'Master'][level - 1]
end
def minimum_ingredients(level)
  return level + 1
end
def get_available_customers(customers, reputation, level)
  available = []
  index = 0
  while index < customers.length
    customer = customers[index]
    if customer.min_reputation <= reputation && customer.difficulty == level
      available << customer
    end
    index += 1
  end
  return available
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
  choices = []
  index = 0
  while index < available.length
    customer = available[index]
    choices << customer unless game.seen_customers.include?(customer.name)
    index += 1
  end
  if choices.empty?
    game.seen_customers = []
    choices = available.dup
  end
  if choices.length > 1
    choices.delete(game.current_customer)
  end
  game.current_customer = choices[rand(choices.length)]
  game.seen_customers << game.current_customer.name
end
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
  player.inventory = []
  index = 0
  while index < game.ingredients.length
    quantity = game.ingredients[index].min_reputation == 0 ? 2 : 0
    player.inventory << quantity
    index += 1
  end
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
  red = 0
  green = 0
  blue = 0
  index = 0
  while index < cauldron.length
    colour = ingredients[cauldron[index]].colour
    red += colour.red
    green += colour.green
    blue += colour.blue
    index += 1
  end
  count = cauldron.length
  return Gosu::Color.rgb(red / count, green / count, blue / count)
end
def mix_ingredients(ingredients, cauldron)
  potion = Potion.new
  return potion if cauldron.empty?
  totals = [0, 0, 0, 0]
  index = 0
  while index < cauldron.length
    ingredient = ingredients[cauldron[index]]
    totals[PropertyType::HEAT] += ingredient.heat
    totals[PropertyType::CALM] += ingredient.calm
    totals[PropertyType::ENERGY] += ingredient.energy
    totals[PropertyType::BITTERNESS] += ingredient.bitterness
    index += 1
  end
  count = cauldron.length
  index = 0
  while index < totals.length
    potion.properties[index] = (totals[index].to_f / count).round
    index += 1
  end
  potion.colour = blend_colour(ingredients, cauldron)
  potion.ingredient_count = count
  return potion
end
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
def clear_cauldron(game)
  index = 0
  while index < game.cauldron.length
    update_inventory(game.player, game.cauldron[index], 1)
    index += 1
  end
  game.cauldron = []
  game.potion = Potion.new
  game.message = 'Cauldron cleared. Ingredients returned.'
end
# Calculate the original match score and rewards.
def get_customer_targets(customer)
  return [customer.target_heat, customer.target_calm,
          customer.target_energy, customer.target_bitterness]
end
def calculate_match_score(potion, customer)
  targets = get_customer_targets(customer)
  difference = 0
  index = 0
  while index < targets.length
    difference += (potion.properties[index] - targets[index]).abs
    index += 1
  end
  score = (100 - difference * 2.5).round
  return [score, 0].max
end
def determine_mood(score)
  if score >= 80
    return CustomerMood::HAPPY
  elsif score >= 50
    return CustomerMood::SATISFIED
  else
    return CustomerMood::DISAPPOINTED
  end
end
def get_mood_name(mood)
  return ['HAPPY', 'SATISFIED', 'DISAPPOINTED'][mood]
end
def calculate_payment(score, customer)
  return (customer.base_payment * score / 100.0).round
end
def calculate_average_score(scores)
  return 0 if scores.empty?
  total = 0
  index = 0
  while index < scores.length
    total += scores[index]
    index += 1
  end
  return (total.to_f / scores.length).round
end
def check_game_end(game)
  return game.player.customers_served >= TOTAL_CUSTOMERS
end
def serve_potion(game)
  return false if game.current_customer.nil? || check_game_end(game)
  required = minimum_ingredients(get_level(game.player.customers_served))
  if game.cauldron.empty?
    game.message = 'Your cauldron is empty.'
    return false
  elsif game.cauldron.length < required
    game.message = "You need at least #{required} ingredients."
    return false
  end
  result = Result.new
  result.match_score = calculate_match_score(game.potion, game.current_customer)
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
  game.message = check_game_end(game) ? 'All customers served!' : 'Potion served successfully.'
  return true
end
# Presentation: Gosu images, sounds, animation and mouse events.
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
    @game = create_game_data
    @ingredient_page = 0
    @animation = 0
    @reaction_alpha = 0
    @muted = false
    @speech = nil
    @guide_line = nil
    @paid_help = nil
    @first_brew_explained = false
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
    @customer_images = []
    @mentor_names = ['Witch', 'Night Witch', 'Fire Wizard']
    index = 0
    while index < 3
      @backgrounds << image_asset('backgrounds', "level#{index + 1}.jpg")
      @mentor_images << image_asset('characters', ['witch.png', 'night_witch.png', 'red_wizard.png'][index])
      @reaction_images << image_asset('characters', ['happy_emote.png', 'wizard.png', 'angry_wizard.png'][index])
      index += 1
    end
    @menu_background = image_asset('backgrounds', 'menu.jpg')
    index = 0
    while index < @game.customers.length
      @customer_images << image_asset('characters', @game.customers[index].image_name + '.png')
      index += 1
    end
    @sound_names = ['click', 'coin', 'splash', 'success', 'error', 'level_up']
    @sounds = []
    index = 0
    while index < @sound_names.length
      @sounds << Gosu::Sample.new(File.join(ROOT, 'sounds', @sound_names[index] + '.wav'))
      index += 1
    end
    @music = Gosu::Song.new(File.join(ROOT, 'sounds', 'background.wav'))
    @guide_lines = []
    file = open_data('guide.txt')
    count = read_field(file).to_i
    index = 0
    while index < count
      line = GuideLine.new
      line.key = read_field(file)
      line.text = read_field(file)
      line.sample = Gosu::Sample.new(File.join(ROOT, 'sounds', 'voices', line.key + '.wav'))
      @guide_lines << line
      index += 1
    end
    file.close
  end
  def play_sound(name)
    return if @muted
    index = @sound_names.index(name)
    @sounds[index].play(0.45) unless index.nil?
  end
  def stop_voice
    @speech.stop unless @speech.nil?
    @speech = nil
  end
  def speaking?
    return !@speech.nil? && @speech.playing?
  end
  def replay_voice
    stop_voice
    @speech = @guide_line.sample.play(0.9) if !@guide_line.nil? && !@muted
  end
  def say(key)
    index = 0
    while index < @guide_lines.length
      if @guide_lines[index].key == key
        @guide_line = @guide_lines[index]
        replay_voice
        return
      end
      index += 1
    end
  end
  def toggle_audio
    @muted = !@muted
    if @muted
      stop_voice
      @music.volume = 0
    else
      @music.volume = 0.22
    end
  end
  def update
    @animation = (@animation + 1) % 120
    if @game.screen == GameScreen::RESULTS
      @reaction_alpha = [255, @reaction_alpha + 9].min
    end
    # Lower music while the mentor is speaking.
    @music.volume = @muted ? 0 : (speaking? ? 0.07 : 0.22)
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
    if served == 0
      say("welcome_#{game.current_customer.image_name}")
    elsif served == 3 || served == 6
      say("welcome_#{current_level(game)}")
    end
  end
  def start_new_game
    @game = create_game_data
    @game.screen = GameScreen::SHOP
    @ingredient_page = 0
    @reaction_alpha = 0
    @first_brew_explained = false
    @paid_help = nil
    shop_voice(@game) unless @game.current_customer.nil?
  end
  def start_brewing(game)
    return if game.current_customer.nil?
    stop_voice
    @guide_line = @paid_help
    game.screen = GameScreen::BREWING
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
  def finish_potion(game)
    unless serve_potion(game)
      play_sound('error')
      return
    end
    stop_voice
    @guide_line = nil
    @paid_help = nil
    @reaction_alpha = 0
    if check_game_end(game) || get_level(game.player.customers_served) > current_level(game)
      play_sound('level_up')
    else
      play_sound(['success', 'click', 'error'][game.result.mood])
    end
  end
  def next_customer(game)
    game.potion = Potion.new
    game.screen = GameScreen::SHOP
    game.message = 'Prepare for your next customer.'
    @ingredient_page = 0
    choose_next_customer(game)
    shop_voice(game) unless game.current_customer.nil?
  end
  # Shared drawing procedures
  def text(message, x, y, colour = WHITE, font = @font)
    font.draw_text(message, x, y, 5, 1, 1, colour)
  end
  def centre(message, x, width, y, colour = WHITE, font = @font)
    text(message, x + (width - font.text_width(message)) / 2.0, y, colour, font)
  end
  def wrap_text(message, x, y, width, font = @small_font, colour = WHITE)
    words = message.split(' ')
    line = ''
    index = 0
    while index < words.length
      candidate = line.empty? ? words[index] : line + ' ' + words[index]
      if !line.empty? && font.text_width(candidate) > width
        text(line, x, y, colour, font)
        y += font.height + 5
        line = words[index]
      else
        line = candidate
      end
      index += 1
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
  def draw_background(game)
    background = @backgrounds[current_level(game) - 1]
    if game.screen == GameScreen::MENU || game.screen == GameScreen::INSTRUCTIONS
      background = @menu_background
    end
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
    button(1018, 30, 146, 37, @muted ? 'Sound: OFF' : 'Sound: ON', GREY)
    Gosu.draw_rect(36, 99, 1128, 5, GREY, 3)
    progress = game.player.customers_served.to_f / TOTAL_CUSTOMERS
    Gosu.draw_rect(36, 99, 1128 * progress, 5, level_colour(game), 4)
  end
  def draw_message(game)
    panel(20, 742, 1160, 40)
    text(game.message, 36, 752, GOLD, @small_font)
    text('F11: Fullscreen | M: Sound | R: Restart | Esc: Exit', 744, 752, WHITE, @small_font)
  end
  def draw_guide(game, tutorial = false)
    panel(20, 130, 255, 596)
    level = tutorial ? 1 : current_level(game)
    centre(@mentor_names[level - 1], 20, 255, 143, GOLD, @heading_font)
    centre('YOUR GUIDE', 20, 255, 177, WHITE, @small_font)
    # Small triangular bob only while the voice is playing.
    bob = speaking? ? (12 - ((@animation % 48) - 24).abs / 2) : 0
    sprite(@mentor_images[level - 1], 34, 202 - bob, 227, 236)
    Gosu.draw_rect(35, 450, 225, 2, GOLD, 3)
    centre(speaking? ? 'Speaking...' : 'Your guide', 20, 255, 460, GOLD, @small_font)
    if @guide_line
      wrap_text(@guide_line.text, 37, 481, 220, @guide_font)
    end
    if game.screen == GameScreen::SHOP || game.screen == GameScreen::BREWING
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
    if active
      index = 0
      while index < 5
        offset = (@animation + index * 15) % 60
        size = (7 + index % 3 * 3) * scale
        Gosu.draw_rect(x + (-80 + index * 39) * scale, y - (15 + offset) * scale, size, size, colour, 4)
        index += 1
      end
    end
  end
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
    centre('F11: Fullscreen | M: Sound', 260, 680, 689, GOLD, @small_font)
  end
  def draw_instructions(game)
    draw_guide(game, true)
    panel(292, 130, 888, 596)
    text('HOW TO PLAY', 320, 156, GOLD, @title_font)
    instructions = ['1. Buy ingredients from the shop or use your starting stock.',
                    '2. Read the customer request and click Start Brewing.',
                    '3. Click ingredients to mix them in the cauldron.',
                    '4. Match the heat, calm, energy and bitterness targets.',
                    '5. Clear the cauldron to recover the unused ingredients.',
                    '6. Serve your potion to earn gold and reputation.',
                    '7. Complete ten customer orders to finish the game.']
    index = 0
    while index < instructions.length
      text(instructions[index], 321, 223 + index * 41)
      index += 1
    end
    text('Level 1: 2 ingredients | Level 2: 3 | Level 3: 4', 321, 534, GOLD)
    text('First order and new levels have guidance. Help costs 100 gold.', 321, 580, WHITE)
    button(555, 645, 350, 50, 'Back to Menu', PURPLE)
  end
  # Ingredient shop and brewing share the same cards and input positions.
  def ingredient_x(slot)
    return 310 + (slot % 2) * 220
  end
  def ingredient_y(slot)
    return 225 + (slot / 2) * 112
  end
  def draw_ingredient_cards(game, shopping)
    slot = 0
    while slot < 6
      index = @ingredient_page * 6 + slot
      if index < game.ingredients.length
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
      slot += 1
    end
    pages = (game.ingredients.length / 6.0).ceil
    if pages > 1
      button(310, 565, 115, 38, 'Previous', GREY)
      button(625, 565, 115, 38, 'Next', GREY)
      centre("Page #{@ingredient_page + 1}/#{pages}", 425, 200, 573)
    end
  end
  def customer_sprite(game, x, y, width, height)
    index = game.customers.index(game.current_customer)
    sprite(@customer_images[index], x, y, width, height) unless index.nil?
  end
  def draw_shop(game)
    draw_guide(game)
    panel(290, 130, 470, 596)
    panel(775, 130, 405, 596)
    text('Ingredient Shop', 310, 148, GOLD, @heading_font)
    text('Click an ingredient to purchase it.', 310, 183, WHITE, @small_font)
    draw_ingredient_cards(game, true)
    centre('Stock up for the next order.', 290, 470, 641, GOLD)
    customer = game.current_customer
    return if customer.nil?
    centre('NEXT CUSTOMER', 775, 405, 147, GOLD, @heading_font)
    centre(customer.name, 775, 405, 188)
    customer_sprite(game, 797, 219, 360, 250)
    wrap_text(customer.request_text, 799, 486, 355, @font)
    level = current_level(game)
    text("Minimum ingredients: #{minimum_ingredients(level)}", 799, 555, GOLD)
    text("Maximum payment: #{customer.base_payment} gold", 799, 589)
    button(799, 641, 357, 58, 'Start Brewing', level_colour(game))
  end
  def draw_properties(game)
    names = ['Heat', 'Calm', 'Energy', 'Bitterness']
    targets = get_customer_targets(game.current_customer)
    text('Property', 800, 461, GOLD, @small_font)
    text('Potion', 958, 461, GOLD, @small_font)
    text('Target', 1082, 461, GOLD, @small_font)
    index = 0
    while index < names.length
      y = 493 + index * 37
      value = game.potion.properties[index]
      colour = game.potion.ingredient_count > 0 && value == targets[index] ? GOOD : WHITE
      text(names[index], 800, y)
      centre(value.to_s, 944, 85, y, colour)
      centre(targets[index].to_s, 1064, 85, y)
      index += 1
    end
  end
  def draw_brewing(game)
    draw_guide(game)
    panel(290, 130, 470, 596)
    panel(775, 130, 405, 596)
    text('Brewing Ingredients', 310, 148, GOLD, @heading_font)
    text('Click ingredients to add them.', 310, 183, WHITE, @small_font)
    draw_ingredient_cards(game, false)
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
    button(530, 645, 210, 54, 'Return to Shop', PURPLE)
    button(799, 645, 357, 54, 'Serve Potion', level_colour(game))
  end
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
    centre("Gold earned: +#{result.payment}", 290, 570, 406, GOLD)
    centre("Reputation change: #{result.reputation_change}", 290, 570, 444)
    centre('CUSTOMER REACTION', 875, 305, 151, GOLD, @heading_font)
    sprite(@reaction_images[result.mood], 893, 217, 269, 370, @reaction_alpha)
    centre(get_mood_name(result.mood), 875, 305, 623, colour, @heading_font)
    if check_game_end(game)
      average = calculate_average_score(game.scores)
      centre('ALL THREE LEVELS COMPLETED!', 290, 570, 489, GOLD, @heading_font)
      centre("Final gold: #{game.player.gold} | Reputation: #{game.player.reputation}", 290, 570, 530)
      centre("Average match score: #{average}%", 290, 570, 568, GOLD)
      button(310, 645, 260, 54, 'Play Again', GREEN)
      button(580, 645, 260, 54, 'Main Menu', PURPLE)
    else
      centre("Customers served: #{game.player.customers_served}/10", 290, 570, 511)
      next_level = get_level(game.player.customers_served)
      if next_level > current_level(game)
        centre("LEVEL #{next_level} UNLOCKED!", 290, 570, 555, GOLD, @heading_font)
      end
      button(375, 645, 400, 54, 'Next Customer', level_colour(game))
    end
  end
  def handle_ingredient_click(game, mx, my)
    slot = 0
    while slot < 6
      index = @ingredient_page * 6 + slot
      if index < game.ingredients.length && clicked?(mx, my, ingredient_x(slot), ingredient_y(slot), 210, 100)
        if game.screen == GameScreen::SHOP
          play_sound(buy_ingredient(game, index) ? 'coin' : 'error')
        else
          play_sound(add_to_cauldron(game, index) ? 'splash' : 'error')
        end
        return true
      end
      slot += 1
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
  def return_to_menu
    stop_voice
    @guide_line = nil
    @paid_help = nil
    @game = create_game_data
    @ingredient_page = 0
  end
  def handle_click(game, mx, my)
    playing = game.screen == GameScreen::SHOP || game.screen == GameScreen::BREWING || game.screen == GameScreen::RESULTS
    if playing && clicked?(mx, my, 1018, 30, 146, 37)
      toggle_audio
      return
    elsif clicked?(mx, my, 40, 674, 215, 36)
      if game.screen == GameScreen::SHOP || game.screen == GameScreen::BREWING
        buy_help(game)
        return
      elsif game.screen == GameScreen::INSTRUCTIONS
        replay_voice
        return
      end
    end
    if game.screen == GameScreen::SHOP || game.screen == GameScreen::BREWING
      return if handle_ingredient_click(game, mx, my)
      handle_page_click(game, mx, my)
    end
    case game.screen
    when GameScreen::MENU
      if clicked?(mx, my, 440, 478, 320, 54)
        play_sound('click')
        start_new_game
      elsif clicked?(mx, my, 440, 548, 320, 54)
        play_sound('click')
        game.screen = GameScreen::INSTRUCTIONS
        say('tutorial')
      elsif clicked?(mx, my, 440, 618, 320, 54)
        close
      end
    when GameScreen::INSTRUCTIONS
      if clicked?(mx, my, 555, 645, 350, 50)
        play_sound('click')
        return_to_menu
      end
    when GameScreen::SHOP
      if clicked?(mx, my, 799, 641, 357, 58)
        play_sound('click')
        start_brewing(game)
      end
    when GameScreen::BREWING
      if clicked?(mx, my, 310, 645, 210, 54)
        clear_cauldron(game)
        play_sound('splash')
      elsif clicked?(mx, my, 530, 645, 210, 54)
        clear_cauldron(game)
        game.screen = GameScreen::SHOP
        game.message = 'Returned to the shop.'
        play_sound('click')
        stop_voice
        @guide_line = @paid_help
      elsif clicked?(mx, my, 799, 645, 357, 54)
        finish_potion(game)
      end
    when GameScreen::RESULTS
      if check_game_end(game)
        if clicked?(mx, my, 310, 645, 260, 54)
          play_sound('click')
          start_new_game
        elsif clicked?(mx, my, 580, 645, 260, 54)
          play_sound('click')
          return_to_menu
        end
      elsif clicked?(mx, my, 375, 645, 400, 54)
        play_sound('click')
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
  def draw
    draw_background(@game)
    case @game.screen
    when GameScreen::MENU
      draw_menu
    when GameScreen::INSTRUCTIONS
      draw_instructions(@game)
    when GameScreen::SHOP
      draw_header(@game)
      draw_shop(@game)
      draw_message(@game)
    when GameScreen::BREWING
      draw_header(@game)
      draw_brewing(@game)
      draw_message(@game)
    when GameScreen::RESULTS
      draw_header(@game)
      draw_results(@game)
      draw_message(@game)
    end
  end
end
AlchemistApp.new.show if __FILE__ == $PROGRAM_NAME
