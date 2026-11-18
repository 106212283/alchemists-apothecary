
require 'gosu'

# Alchemist's Apothecary
# Amani Abdelrahim Elsayed
# Student ID: 106212283

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

# Composite data types

class Ingredient
  attr_accessor :name, :heat, :calm, :energy,
                :bitterness, :colour, :cost, :min_reputation
end

class Customer
  attr_accessor :name, :request_text, :target_heat,
                :target_calm, :target_energy, :target_bitterness,
                :base_payment, :min_reputation, :difficulty
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
  attr_accessor :screen, :ingredients, :customers, :cauldron,
                :potion, :current_customer, :result, :player,
                :message, :scores
end

# File handling

def load_ingredients(filename)
  ingredients = []

  if !File.exist?(filename)
    puts "Error: Cannot find #{filename}"
    exit
  end

  file = File.new(filename, "r")
  count = file.gets.to_i
  index = 0

  while index < count
    ingredient = Ingredient.new
    ingredient.name = file.gets.chomp
    ingredient.heat = file.gets.to_i
    ingredient.calm = file.gets.to_i
    ingredient.energy = file.gets.to_i
    ingredient.bitterness = file.gets.to_i

    red = file.gets.to_i
    green = file.gets.to_i
    blue = file.gets.to_i

    ingredient.colour = Gosu::Color.rgb(red, green, blue)
    ingredient.cost = file.gets.to_i
    ingredient.min_reputation = file.gets.to_i

    ingredients << ingredient
    index += 1
  end

  file.close
  return ingredients
end

def load_customers(filename)
  customers = []

  if !File.exist?(filename)
    puts "Error: Cannot find #{filename}"
    exit
  end

  file = File.new(filename, "r")
  count = file.gets.to_i
  index = 0

  while index < count
    customer = Customer.new
    customer.name = file.gets.chomp
    customer.request_text = file.gets.chomp
    customer.target_heat = file.gets.to_i
    customer.target_calm = file.gets.to_i
    customer.target_energy = file.gets.to_i
    customer.target_bitterness = file.gets.to_i
    customer.base_payment = file.gets.to_i
    customer.min_reputation = file.gets.to_i
    customer.difficulty = file.gets.to_i

    customers << customer
    index += 1
  end

  file.close
  return customers
end

# Difficulty and customer selection

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
  case level
  when Difficulty::EASY
    return "Apprentice Alchemist"
  when Difficulty::MEDIUM
    return "Skilled Alchemist"
  when Difficulty::HARD
    return "Master Alchemist"
  end
end

def minimum_ingredients(level)
  return level + 1
end

def get_available_customers(customers, reputation, level)
  available = []
  index = 0

  while index < customers.length
    customer = customers[index]

    if customer.min_reputation <= reputation &&
       customer.difficulty == level
      available << customer
    end

    index += 1
  end

  return available
end

def choose_next_customer(game)
  level = get_level(game.player.customers_served)
  available = get_available_customers(
    game.customers, game.player.reputation, level
  )

  if available.length > 0
    game.current_customer = available[rand(available.length)]
  else
    game.current_customer = nil
    game.message = "No customers available."
  end
end

# Initialise game data

def create_game_data
  game = GameData.new
  game.ingredients = load_ingredients("ingredients.txt")
  game.customers = load_customers("customers.txt")
  game.screen = GameScreen::MENU
  game.cauldron = []
  game.potion = Potion.new
  game.result = Result.new
  game.scores = []

  player = Player.new
  player.gold = STARTING_GOLD
  player.reputation = 0
  player.customers_served = 0
  player.inventory = []

  index = 0

  while index < game.ingredients.length
    if game.ingredients[index].min_reputation == 0
      player.inventory << 2
    else
      player.inventory << 0
    end
    index += 1
  end

  game.player = player
  game.message = "Welcome to the Apothecary!"
  choose_next_customer(game)

  return game
end

# Shop and inventory

def update_inventory(player, index, amount)
  player.inventory[index] += amount
end

def buy_ingredient(game, index)
  ingredient = game.ingredients[index]

  if game.player.reputation < ingredient.min_reputation
    game.message = "This ingredient is locked."
  elsif game.player.gold < ingredient.cost
    game.message = "Not enough gold."
  else
    game.player.gold -= ingredient.cost
    update_inventory(game.player, index, 1)
    game.message = "Purchased #{ingredient.name}."
  end
end

# Potion calculations

def blend_colour(ingredients, cauldron)
  if cauldron.length == 0
    return Gosu::Color.rgb(45, 45, 55)
  end

  red = 0
  green = 0
  blue = 0
  index = 0

  while index < cauldron.length
    ingredient = ingredients[cauldron[index]]
    red += ingredient.colour.red
    green += ingredient.colour.green
    blue += ingredient.colour.blue
    index += 1
  end

  count = cauldron.length
  return Gosu::Color.rgb(red / count, green / count, blue / count)
end

def mix_ingredients(ingredients, cauldron)
  potion = Potion.new

  if cauldron.length == 0
    return potion
  end

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
    game.message = "This ingredient is out of stock."
  else
    game.cauldron << index
    update_inventory(game.player, index, -1)
    game.potion = mix_ingredients(game.ingredients, game.cauldron)
    game.message = "#{game.ingredients[index].name} added."
  end
end

def clear_cauldron(game)
  index = 0

  while index < game.cauldron.length
    update_inventory(game.player, game.cauldron[index], 1)
    index += 1
  end

  game.cauldron = []
  game.potion = Potion.new
  game.message = "Cauldron cleared. Ingredients returned."
end

# Scoring and rewards

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

  if score < 0
    score = 0
  end

  return score
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
  case mood
  when CustomerMood::HAPPY
    return "HAPPY"
  when CustomerMood::SATISFIED
    return "SATISFIED"
  when CustomerMood::DISAPPOINTED
    return "DISAPPOINTED"
  end
end

def calculate_payment(score, customer)
  return (customer.base_payment * score / 100.0).round
end

def calculate_average_score(scores)
  if scores.length == 0
    return 0
  end

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
  if game.current_customer == nil
    game.message = "No customer available."
    return
  end

  level = get_level(game.player.customers_served)
  required = minimum_ingredients(level)

  if game.cauldron.length == 0
    game.message = "Your cauldron is empty."
    return
  elsif game.cauldron.length < required
    game.message = "You need at least #{required} ingredients."
    return
  end

  result = Result.new
  result.match_score = calculate_match_score(game.potion, game.current_customer)
  result.mood = determine_mood(result.match_score)
  result.payment = calculate_payment(result.match_score, game.current_customer)

  case result.mood
  when CustomerMood::HAPPY
    result.reputation_change = 1
  when CustomerMood::SATISFIED
    result.reputation_change = 0
  when CustomerMood::DISAPPOINTED
    result.reputation_change = -1
  end

  old_reputation = game.player.reputation
  game.player.gold += result.payment
  game.player.reputation += result.reputation_change

  if game.player.reputation < 0
    game.player.reputation = 0
  end

  result.reputation_change = game.player.reputation - old_reputation

  game.scores << result.match_score
  game.player.customers_served += 1
  game.result = result
  game.cauldron = []
  game.screen = GameScreen::RESULTS

  if check_game_end(game)
    game.message = "Congratulations! All customers served."
  else
    game.message = "Potion served successfully."
  end
end

# Graphical interface

class AlchemistApp < Gosu::Window
  WIDTH = 1000
  HEIGHT = 760

  BACKGROUND = Gosu::Color.rgb(22, 23, 32)
  PANEL = Gosu::Color.rgb(39, 42, 53)
  GOLD = Gosu::Color.rgb(235, 193, 112)
  WHITE = Gosu::Color::WHITE
  GREY = Gosu::Color.rgb(76, 80, 90)
  GREEN = Gosu::Color.rgb(66, 108, 85)
  BLUE = Gosu::Color.rgb(55, 89, 140)
  PURPLE = Gosu::Color.rgb(112, 77, 150)
  RED = Gosu::Color.rgb(195, 75, 85)

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = "Alchemist's Apothecary"

    @title_font = Gosu::Font.new(36)
    @heading_font = Gosu::Font.new(26)
    @font = Gosu::Font.new(20)
    @small_font = Gosu::Font.new(17)
    @score_font = Gosu::Font.new(65)

    @game = create_game_data
    @ingredient_page = 0
    @animation = 0
  end

  def needs_cursor?
    return true
  end

  def update
    @animation += 1

    if @animation >= 120
      @animation = 0
    end
  end

  # Reusable drawing methods

  def level_colour(game)
    served = game.player.customers_served

    if game.screen == GameScreen::RESULTS
      served -= 1
    end

    case get_level(served)
    when Difficulty::EASY
      return GREEN
    when Difficulty::MEDIUM
      return BLUE
    when Difficulty::HARD
      return PURPLE
    end
  end

  def draw_text(message, x, y, colour = WHITE)
    @font.draw_text(message, x, y, 4, 1, 1, colour)
  end

  def centred_text(font, message, y, colour)
    x = (WIDTH - font.text_width(message)) / 2
    font.draw_text(message, x, y, 4, 1, 1, colour)
  end

  def draw_panel(x, y, width, height)
    Gosu.draw_rect(x, y, width, height, PANEL, 1)
  end

  def clicked?(mx, my, x, y, width, height)
    return mx >= x && mx < x + width &&
           my >= y && my < y + height
  end

  def draw_button(x, y, width, height, label, colour)
    if clicked?(mouse_x, mouse_y, x, y, width, height)
      Gosu.draw_rect(x - 2, y - 2, width + 4, height + 4, GOLD, 2)
    end

    Gosu.draw_rect(x, y, width, height, colour, 3)

    tx = x + (width - @font.text_width(label)) / 2
    ty = y + (height - @font.height) / 2

    @font.draw_text(label, tx, ty, 4)
  end

  def draw_request(request, x, y)
    words = request.split(" ")
    line = ""
    index = 0

    while index < words.length
      next_line = line + words[index] + " "

      if @small_font.text_width(next_line) > 380
        @small_font.draw_text(line, x, y, 4)
        y += 22
        line = words[index] + " "
      else
        line = next_line
      end

      index += 1
    end

    @small_font.draw_text(line, x, y, 4)
  end

  # Decorative background

  def draw_background
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, BACKGROUND, -2)
    Gosu.draw_rect(10, 10, 980, 3, GOLD, -1)
    Gosu.draw_rect(10, 747, 980, 3, GOLD, -1)

    index = 0

    while index < 12
      x = 35 + index * 84
      Gosu.draw_rect(x, 25, 3, 12, GOLD, 0)
      index += 1
    end
  end

  # Main menu

  def draw_menu
    centred_text(@title_font, "ALCHEMIST'S APOTHECARY", 100, GOLD)
    centred_text(@font, "The art of magical potion brewing", 155, WHITE)

    draw_cauldron_at(500, 310, Gosu::Color.rgb(150, 90, 210), true)

    draw_button(350, 440, 300, 55, "Play Game", GREEN)
    draw_button(350, 510, 300, 55, "How to Play", PURPLE)
    draw_button(350, 580, 300, 55, "Exit Game", GREY)

    centred_text(@small_font, "F11: Fullscreen | ESC: Exit", 700, GOLD)
  end

  def draw_instructions
    draw_panel(100, 60, 800, 640)
    centred_text(@title_font, "HOW TO PLAY", 90, GOLD)

    instructions = [
      "1. Purchase ingredients from the shop.",
      "2. Read your customer's potion request.",
      "3. Click ingredients to add them to the cauldron.",
      "4. Match the four requested potion properties.",
      "5. Clear the cauldron to recover unused ingredients.",
      "6. Serve potions to earn gold and reputation.",
      "7. Serve ten customers to complete the game."
    ]

    index = 0

    while index < instructions.length
      draw_text(instructions[index], 140, 155 + index * 40)
      index += 1
    end

    draw_text("Level 1: Apprentice - 2 ingredients minimum", 140, 465, GOLD)
    draw_text("Level 2: Skilled - 3 ingredients minimum", 140, 500, GOLD)
    draw_text("Level 3: Master - 4 ingredients minimum", 140, 535, GOLD)

    draw_button(350, 610, 300, 50, "Back to Menu", PURPLE)
  end

  # Gameplay header and messages

  def draw_header(game)
    Gosu.draw_rect(20, 20, 960, 130, PANEL, 1)

    @title_font.draw_text(
      "ALCHEMIST'S APOTHECARY", 35, 30, 4, 1, 1, GOLD
    )

    draw_text("Gold: #{game.player.gold}", 35, 80, GOLD)
    draw_text("Reputation: #{game.player.reputation}", 230, 80)

    round = game.player.customers_served + 1

    if game.screen == GameScreen::RESULTS
      round = game.player.customers_served
    end

    level = get_level(round - 1)

    draw_text("Customer: #{round}/10", 470, 80)
    draw_text("Level #{level}", 830, 80, GOLD)

    progress = game.player.customers_served.to_f / TOTAL_CUSTOMERS

    Gosu.draw_rect(35, 120, 930, 10, GREY, 2)
    Gosu.draw_rect(35, 120, 930 * progress, 10, level_colour(game), 3)
  end

  def draw_message(game)
    draw_panel(25, 710, 950, 35)
    draw_text(game.message, 40, 716, GOLD)
  end

  # Ingredient cards

  def ingredient_x(slot)
    return 45 + (slot % 2) * 240
  end

  def ingredient_y(slot)
    return 245 + (slot / 2) * 105
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
        locked = game.player.reputation < ingredient.min_reputation
        colour = level_colour(game)

        if (shopping && locked) || (!shopping && quantity == 0)
          colour = GREY
        end

        if clicked?(mouse_x, mouse_y, x, y, 220, 90)
          Gosu.draw_rect(x - 2, y - 2, 224, 94, GOLD, 2)
        end

        Gosu.draw_rect(x, y, 220, 90, colour, 3)

        # Small ingredient bottle
        Gosu.draw_rect(x + 17, y + 10, 13, 10, GOLD, 4)
        Gosu.draw_rect(x + 12, y + 20, 23, 35, ingredient.colour, 4)
        Gosu.draw_rect(x + 16, y + 24, 3, 21, WHITE, 4)

        draw_text(ingredient.name, x + 45, y + 8)
        @small_font.draw_text("Owned: #{quantity}", x + 45, y + 35, 4)

        if shopping && locked
          label = "Locked: reputation #{ingredient.min_reputation}"
        elsif shopping
          label = "Buy: #{ingredient.cost} gold"
        elsif quantity == 0
          label = "Out of stock"
        else
          label = "Click to add"
        end

        @small_font.draw_text(label, x + 13, y + 65, 4)
      end

      slot += 1
    end

    pages = (game.ingredients.length / 6.0).ceil

    if pages > 1
      draw_button(45, 565, 110, 35, "Previous", GREY)
      draw_button(385, 565, 120, 35, "Next", GREY)
      draw_text("Page #{@ingredient_page + 1}/#{pages}", 220, 570)
    end
  end

  # Shop screen

  def draw_shop(game)
    draw_panel(25, 165, 500, 475)
    draw_panel(545, 165, 430, 475)

    @heading_font.draw_text("Ingredient Shop", 45, 180, 4, 1, 1, GOLD)
    draw_text("Click an ingredient to purchase it.", 45, 215)

    draw_ingredient_cards(game, true)

    @heading_font.draw_text("Next Customer", 565, 180, 4, 1, 1, GOLD)

    if game.current_customer != nil
      customer = game.current_customer
      @heading_font.draw_text(customer.name, 565, 240, 4)
      draw_request(customer.request_text, 565, 285)
      draw_text("Maximum payment: #{customer.base_payment} gold", 565, 425)
    end

    level = get_level(game.player.customers_served)
    draw_text(get_level_name(level), 565, 345, GOLD)
    draw_text("Minimum ingredients: #{minimum_ingredients(level)}", 565, 390)

    draw_button(565, 550, 390, 58, "Start Brewing", level_colour(game))
    draw_text("Purchase ingredients and prepare your next potion.", 35, 665)
  end

  # Draw reusable animated cauldron

  def draw_cauldron_at(x, y, colour, active)
    body = Gosu::Color.rgb(65, 68, 78)
    rim = Gosu::Color.rgb(115, 120, 135)

    Gosu.draw_rect(x - 155, y + 15, 50, 25, rim, 2)
    Gosu.draw_rect(x + 105, y + 15, 50, 25, rim, 2)

    Gosu.draw_rect(x - 75, y + 110, 30, 20, rim, 2)
    Gosu.draw_rect(x + 45, y + 110, 30, 20, rim, 2)

    Gosu.draw_quad(
      x - 115, y, body,
      x + 115, y, body,
      x + 80, y + 115, body,
      x - 80, y + 115, body, 3
    )

    Gosu.draw_rect(x - 125, y - 8, 250, 30, rim, 3)
    Gosu.draw_rect(x - 115, y - 2, 230, 18, colour, 4)

    if active
      index = 0

      while index < 5
        offset = (@animation + index * 23) % 60
        bubble_x = x - 85 + index * 40
        bubble_y = y - 15 - offset
        size = 6 + index % 3 * 3

        Gosu.draw_rect(bubble_x, bubble_y, size, size, colour, 4)
        index += 1
      end
    end
  end

  def draw_cauldron(potion)
    draw_cauldron_at(
      760, 310, potion.colour, potion.ingredient_count > 0
    )
  end

  # Potion properties

  def draw_properties(game)
    names = ["Heat", "Calm", "Energy", "Bitterness"]
    targets = get_customer_targets(game.current_customer)

    draw_text("Property", 565, 485, GOLD)
    draw_text("Potion", 735, 485, GOLD)
    draw_text("Target", 855, 485, GOLD)

    index = 0

    while index < names.length
      y = 515 + index * 28
      value = game.potion.properties[index]
      target = targets[index]
      colour = WHITE

      if game.potion.ingredient_count > 0 && value == target
        colour = Gosu::Color.rgb(140, 220, 170)
      end

      draw_text(names[index], 565, y)
      draw_text(value.to_s, 755, y, colour)
      draw_text(target.to_s, 875, y)

      index += 1
    end
  end

  # Brewing screen

  def draw_brewing(game)
    draw_panel(25, 165, 500, 475)
    draw_panel(545, 165, 430, 475)

    @heading_font.draw_text("Brewing Ingredients", 45, 180, 4, 1, 1, GOLD)
    draw_text("Click an ingredient to add it.", 45, 215)
    draw_ingredient_cards(game, false)

    if game.current_customer != nil
      @heading_font.draw_text(game.current_customer.name, 565, 180, 4, 1, 1, GOLD)
      draw_request(game.current_customer.request_text, 565, 215)

      draw_cauldron(game.potion)

      level = get_level(game.player.customers_served)
      required = minimum_ingredients(level)

      draw_text("Ingredients: #{game.potion.ingredient_count} / Min #{required}", 565, 450, GOLD)
      draw_properties(game)
    end

    draw_button(35, 655, 220, 45, "Clear Cauldron", GREY)
    draw_button(275, 655, 230, 45, "Return to Shop", PURPLE)
    draw_button(555, 655, 410, 45, "Serve Potion", level_colour(game))
  end

  # Result screen

  def draw_results(game)
    draw_panel(150, 165, 700, 530)

    result = game.result
    colour = Gosu::Color.rgb(140, 220, 170)

    if result.mood == CustomerMood::SATISFIED
      colour = GOLD
    elsif result.mood == CustomerMood::DISAPPOINTED
      colour = RED
    end

    centred_text(@heading_font, "POTION RESULTS", 185, GOLD)
    centred_text(@font, game.current_customer.name, 230, WHITE)
    centred_text(@score_font, "#{result.match_score}%", 265, colour)

    Gosu.draw_rect(250, 350, 500, 20, GREY, 2)
    Gosu.draw_rect(250, 350, result.match_score * 5, 20, colour, 3)

    centred_text(@font, "Customer mood: #{get_mood_name(result.mood)}", 390, colour)
    centred_text(@font, "Gold earned: +#{result.payment}", 425, GOLD)
    centred_text(@font, "Reputation change: #{result.reputation_change}", 460, WHITE)

    if check_game_end(game)
      average = calculate_average_score(game.scores)

      centred_text(@heading_font, "ALL THREE LEVELS COMPLETED!", 495, GOLD)
      centred_text(@font, "Final gold: #{game.player.gold} | Reputation: #{game.player.reputation}", 535, WHITE)
      centred_text(@font, "Average match score: #{average}%", 565, GOLD)

      draw_button(225, 620, 260, 50, "Play Again", GREEN)
      draw_button(515, 620, 260, 50, "Main Menu", PURPLE)
    else
      current_level = get_level(game.player.customers_served - 1)
      next_level = get_level(game.player.customers_served)

      centred_text(@font, "Customers served: #{game.player.customers_served}/10", 520, WHITE)

      if next_level > current_level
        centred_text(@heading_font, "LEVEL #{next_level} UNLOCKED!", 555, GOLD)
      end

      draw_button(300, 620, 400, 50, "Next Customer", level_colour(game))
    end
  end

  # Ingredient selection

  def handle_ingredient_click(game, mx, my)
    slot = 0

    while slot < 6
      index = @ingredient_page * 6 + slot

      if index < game.ingredients.length
        x = ingredient_x(slot)
        y = ingredient_y(slot)

        if clicked?(mx, my, x, y, 220, 90)
          if game.screen == GameScreen::SHOP
            buy_ingredient(game, index)
          else
            add_to_cauldron(game, index)
          end
          return true
        end
      end

      slot += 1
    end

    return false
  end

  def handle_page_click(game, mx, my)
    pages = (game.ingredients.length / 6.0).ceil

    if pages > 1
      if clicked?(mx, my, 45, 565, 110, 35)
        if @ingredient_page > 0
          @ingredient_page -= 1
        end
      elsif clicked?(mx, my, 385, 565, 120, 35)
        if @ingredient_page < pages - 1
          @ingredient_page += 1
        end
      end
    end
  end

  # Mouse controls

  def handle_click(game, mx, my)
    if game.screen == GameScreen::SHOP ||
       game.screen == GameScreen::BREWING

      if handle_ingredient_click(game, mx, my)
        return
      end

      handle_page_click(game, mx, my)
    end

    case game.screen
    when GameScreen::MENU
      if clicked?(mx, my, 350, 440, 300, 55)
        @game = create_game_data
        @game.screen = GameScreen::SHOP
        @ingredient_page = 0
      elsif clicked?(mx, my, 350, 510, 300, 55)
        game.screen = GameScreen::INSTRUCTIONS
      elsif clicked?(mx, my, 350, 580, 300, 55)
        close
      end

    when GameScreen::INSTRUCTIONS
      if clicked?(mx, my, 350, 610, 300, 50)
        game.screen = GameScreen::MENU
      end

    when GameScreen::SHOP
      if clicked?(mx, my, 565, 550, 390, 58)
        if game.current_customer != nil
          game.screen = GameScreen::BREWING
          game.message = "Create a potion for your customer."
        end
      end

    when GameScreen::BREWING
      if clicked?(mx, my, 35, 655, 220, 45)
        clear_cauldron(game)
      elsif clicked?(mx, my, 275, 655, 230, 45)
        clear_cauldron(game)
        game.screen = GameScreen::SHOP
        game.message = "Returned to the shop."
      elsif clicked?(mx, my, 555, 655, 410, 45)
        serve_potion(game)
      end

    when GameScreen::RESULTS
      if check_game_end(game)
        if clicked?(mx, my, 225, 620, 260, 50)
          @game = create_game_data
          @game.screen = GameScreen::SHOP
          @ingredient_page = 0
        elsif clicked?(mx, my, 515, 620, 260, 50)
          @game = create_game_data
          @ingredient_page = 0
        end
      elsif clicked?(mx, my, 300, 620, 400, 50)
        game.potion = Potion.new
        game.message = "Prepare for your next customer."
        choose_next_customer(game)
        game.screen = GameScreen::SHOP
        @ingredient_page = 0
      end
    end
  end

  # Keyboard controls

  def button_down(id)
    case id
    when Gosu::MS_LEFT
      handle_click(@game, mouse_x, mouse_y)
    when Gosu::KB_ESCAPE
      close
    when Gosu::KB_R
      @game = create_game_data
      @ingredient_page = 0
    else
      super
    end
  end

  # Main drawing procedure

  def draw
    draw_background

    case @game.screen
    when GameScreen::MENU
      draw_menu
    when GameScreen::INSTRUCTIONS
      draw_instructions
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

AlchemistApp.new.show
