
require 'gosu'

# Alchemist's Apothecary
# Name: Amani Abdelrahim Elsayed
# Student ID: 106212283

# Enumerations and constants

module GameScreen
  SHOP = 0
  BREWING = 1
  RESULTS = 2
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
                :bitterness, :colour, :cost,
                :min_reputation
end

class Customer
  attr_accessor :name, :request_text,
                :target_heat, :target_calm,
                :target_energy, :target_bitterness,
                :base_payment, :min_reputation,
                :difficulty
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
  attr_accessor :match_score, :payment,
                :reputation_change, :mood
end

class Player
  attr_accessor :gold, :reputation,
                :customers_served, :inventory
end

class GameData
  attr_accessor :screen, :ingredients, :customers,
                :cauldron, :potion, :current_customer,
                :result, :player, :message
end

# File handling

def load_ingredients(filename)
  ingredients = []

  if !File.exist?(filename)
    puts "Error: Ingredient file not found."
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
    puts "Error: Customer file not found."
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

# Difficulty levels

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

# Customer selection

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

# Game initialisation

def create_game_data
  game = GameData.new
  game.ingredients = load_ingredients("ingredients.txt")
  game.customers = load_customers("customers.txt")
  game.screen = GameScreen::SHOP
  game.cauldron = []
  game.potion = Potion.new
  game.result = Result.new

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
  game.message = "Welcome! Stock up on ingredients."

  choose_next_customer(game)
  return game
end

# Inventory management

def update_inventory(player, index, amount)
  player.inventory[index] += amount
end

def buy_ingredient(game, index)
  ingredient = game.ingredients[index]

  if game.player.reputation < ingredient.min_reputation
    game.message = "This ingredient is locked."
  elsif game.player.gold < ingredient.cost
    game.message = "You do not have enough gold."
  else
    game.player.gold -= ingredient.cost
    update_inventory(game.player, index, 1)
    game.message = "Purchased #{ingredient.name}."
  end
end

# Blend the colours of all selected ingredients

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

  return Gosu::Color.rgb(
    red / count, green / count, blue / count
  )
end

# Calculate potion properties

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

  potion.ingredient_count = count
  potion.colour = blend_colour(ingredients, cauldron)

  return potion
end

# Cauldron management

def add_to_cauldron(game, index)
  if game.player.inventory[index] <= 0
    game.message = "You have none of this ingredient."
  else
    game.cauldron << index
    update_inventory(game.player, index, -1)

    game.potion = mix_ingredients(
      game.ingredients, game.cauldron
    )

    game.message = "#{game.ingredients[index].name} added."
  end
end

def clear_cauldron(game)
  index = 0

  while index < game.cauldron.length
    ingredient_index = game.cauldron[index]
    update_inventory(game.player, ingredient_index, 1)
    index += 1
  end

  game.cauldron = []
  game.potion = Potion.new
  game.message = "Cauldron cleared. Ingredients returned."
end

# Match score and customer rewards

def get_customer_targets(customer)
  return [
    customer.target_heat,
    customer.target_calm,
    customer.target_energy,
    customer.target_bitterness
  ]
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

def check_game_end(game)
  return game.player.customers_served >= TOTAL_CUSTOMERS
end

# Serve the completed potion

def serve_potion(game)
  if game.current_customer == nil
    game.message = "No customer available."
    return
  end

  if game.cauldron.length == 0
    game.message = "Add ingredients before serving."
    return
  end

  level = get_level(game.player.customers_served)
  required = minimum_ingredients(level)

  if game.cauldron.length < required
    game.message = "You need at least #{required} ingredients."
    return
  end

  result = Result.new
  result.match_score = calculate_match_score(
    game.potion, game.current_customer
  )

  result.mood = determine_mood(result.match_score)
  result.payment = calculate_payment(
    result.match_score, game.current_customer
  )

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

  result.reputation_change =
    game.player.reputation - old_reputation

  game.player.customers_served += 1
  game.result = result
  game.cauldron = []
  game.screen = GameScreen::RESULTS

  if check_game_end(game)
    game.message = "All three levels completed!"
  else
    game.message = "Potion served successfully."
  end
end

# Main Gosu window

class AlchemistApp < Gosu::Window
  WIDTH = 1000
  HEIGHT = 760

  BACKGROUND = Gosu::Color.rgb(23, 25, 35)
  PANEL = Gosu::Color.rgb(38, 42, 55)
  GOLD = Gosu::Color.rgb(235, 193, 112)
  GREEN = Gosu::Color.rgb(66, 108, 85)
  PURPLE = Gosu::Color.rgb(112, 83, 160)
  GREY = Gosu::Color.rgb(76, 80, 90)
  RED = Gosu::Color.rgb(200, 85, 90)
  WHITE = Gosu::Color::WHITE

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = "Alchemist's Apothecary"

    @title_font = Gosu::Font.new(34)
    @heading_font = Gosu::Font.new(26)
    @font = Gosu::Font.new(20)
    @small_font = Gosu::Font.new(17)
    @score_font = Gosu::Font.new(65)

    @game = create_game_data
    @ingredient_page = 0
  end

  def needs_cursor?
    return true
  end

  def update
  end

  # Reusable drawing procedures

  def draw_text(message, x, y, colour = WHITE)
    @font.draw_text(message, x, y, 3, 1, 1, colour)
  end

  def draw_panel(x, y, width, height)
    Gosu.draw_rect(x, y, width, height, PANEL, 0)
  end

  def draw_button(x, y, width, height, label, colour)
    if clicked?(mouse_x, mouse_y, x, y, width, height)
      Gosu.draw_rect(x - 2, y - 2, width + 4, height + 4, GOLD, 1)
    end

    Gosu.draw_rect(x, y, width, height, colour, 2)

    text_x = x + (width - @font.text_width(label)) / 2
    text_y = y + (height - @font.height) / 2

    @font.draw_text(label, text_x, text_y, 3)
  end

  def clicked?(mx, my, x, y, width, height)
    return mx >= x && mx < x + width &&
           my >= y && my < y + height
  end

  def draw_request(request, x, y)
    words = request.split(" ")
    line = ""
    index = 0

    while index < words.length
      next_line = line + words[index] + " "

      if @small_font.text_width(next_line) > 380
        @small_font.draw_text(line, x, y, 3)
        y += 22
        line = words[index] + " "
      else
        line = next_line
      end

      index += 1
    end

    @small_font.draw_text(line, x, y, 3)
  end

  # Common header

  def draw_header(game)
    Gosu.draw_rect(0, 0, WIDTH, 145, PANEL, 0)

    @title_font.draw_text(
      "ALCHEMIST'S APOTHECARY", 25, 18, 3, 1, 1, GOLD
    )

    draw_text("Gold: #{game.player.gold}", 25, 70, GOLD)
    draw_text("Reputation: #{game.player.reputation}", 245, 70)

    round = game.player.customers_served + 1

    if game.screen == GameScreen::RESULTS
      round = game.player.customers_served
    end

    level = get_level(round - 1)

    draw_text("Customer: #{round}/10", 490, 70)
    draw_text("Level #{level}", 815, 70, GOLD)

    progress = game.player.customers_served.to_f / TOTAL_CUSTOMERS

    Gosu.draw_rect(25, 116, 950, 10, GREY, 1)
    Gosu.draw_rect(25, 116, 950 * progress, 10, GREEN, 2)
  end

  def draw_message(game)
    Gosu.draw_rect(25, 710, 950, 35, PANEL, 1)
    draw_text(game.message, 40, 716, GOLD)
  end

  # Ingredient card layout

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
        colour = GREEN

        if (shopping && locked) || (!shopping && quantity == 0)
          colour = GREY
        end

        if clicked?(mouse_x, mouse_y, x, y, 220, 90)
          Gosu.draw_rect(x - 2, y - 2, 224, 94, GOLD, 1)
        end

        Gosu.draw_rect(x, y, 220, 90, colour, 2)
        Gosu.draw_rect(x + 13, y + 12, 17, 43, ingredient.colour, 3)

        draw_text(ingredient.name, x + 41, y + 8)
        @small_font.draw_text("Owned: #{quantity}", x + 41, y + 35, 3)

        if shopping && locked
          label = "Locked: reputation #{ingredient.min_reputation}"
        elsif shopping
          label = "Buy: #{ingredient.cost} gold"
        elsif quantity == 0
          label = "Out of stock"
        else
          label = "Click to add"
        end

        @small_font.draw_text(label, x + 13, y + 65, 3)
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

  # Ingredient shop screen

  def draw_shop(game)
    draw_panel(25, 165, 500, 465)
    draw_panel(545, 165, 430, 465)

    @heading_font.draw_text("Ingredient Shop", 45, 180, 3, 1, 1, GOLD)
    draw_text("Click an ingredient to purchase it.", 45, 215)

    draw_ingredient_cards(game, true)

    @heading_font.draw_text("Next Customer", 565, 180, 3, 1, 1, GOLD)

    if game.current_customer != nil
      customer = game.current_customer

      @heading_font.draw_text(customer.name, 565, 240, 3)
      draw_request(customer.request_text, 565, 285)
      draw_text("Maximum payment: #{customer.base_payment} gold", 565, 425)
    end

    level = get_level(game.player.customers_served)
    required = minimum_ingredients(level)

    draw_text(get_level_name(level), 565, 345, GOLD)
    draw_text("Minimum ingredients: #{required}", 565, 390)

    draw_button(565, 550, 390, 58, "Start Brewing", PURPLE)

    draw_text("Prepare ingredients before serving your customer.", 35, 660)
  end

  # Draw cauldron using Gosu shapes

  def draw_cauldron(potion)
    body = Gosu::Color.rgb(65, 68, 78)
    rim = Gosu::Color.rgb(110, 115, 125)

    # Handles and feet
    Gosu.draw_rect(610, 325, 60, 22, rim, 1)
    Gosu.draw_rect(850, 325, 60, 22, rim, 1)
    Gosu.draw_rect(690, 420, 35, 20, rim, 1)
    Gosu.draw_rect(800, 420, 35, 20, rim, 1)

    # Main body
    Gosu.draw_quad(
      650, 315, body,
      875, 315, body,
      835, 425, body,
      690, 425, body, 2
    )

    # Rim and liquid
    Gosu.draw_rect(640, 300, 245, 30, rim, 2)
    Gosu.draw_rect(650, 306, 225, 18, potion.colour, 3)

    if potion.ingredient_count > 0
      Gosu.draw_rect(690, 280, 13, 13, potion.colour, 3)
      Gosu.draw_rect(760, 265, 17, 17, potion.colour, 3)
      Gosu.draw_rect(820, 278, 10, 10, potion.colour, 3)
    end
  end

  # Display potion properties and customer targets

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

    @heading_font.draw_text("Brewing Ingredients", 45, 180, 3, 1, 1, GOLD)
    draw_text("Click an ingredient to add it.", 45, 215)

    draw_ingredient_cards(game, false)

    if game.current_customer != nil
      @heading_font.draw_text(game.current_customer.name, 565, 180, 3, 1, 1, GOLD)

      draw_request(game.current_customer.request_text, 565, 215)
      draw_cauldron(game.potion)

      level = get_level(game.player.customers_served)
      required = minimum_ingredients(level)

      draw_text("Ingredients: #{game.potion.ingredient_count} / Min #{required}", 565, 450, GOLD)
      draw_properties(game)
    end

    draw_button(35, 655, 220, 45, "Clear Cauldron", GREY)
    draw_button(275, 655, 230, 45, "Return to Shop", PURPLE)
    draw_button(555, 655, 410, 45, "Serve Potion", GREEN)
  end

  # Results screen

  def draw_results(game)
    draw_panel(150, 165, 700, 520)

    result = game.result
    colour = Gosu::Color.rgb(140, 220, 170)

    if result.mood == CustomerMood::SATISFIED
      colour = GOLD
    elsif result.mood == CustomerMood::DISAPPOINTED
      colour = RED
    end

    @heading_font.draw_text("Potion Results", 390, 185, 3, 1, 1, GOLD)
    draw_text("Customer: #{game.current_customer.name}", 310, 235)

    score_text = "#{result.match_score}%"
    score_x = 500 - @score_font.text_width(score_text) / 2

    @score_font.draw_text(score_text, score_x, 275, 3, 1, 1, colour)

    Gosu.draw_rect(250, 365, 500, 20, GREY, 1)
    Gosu.draw_rect(250, 365, result.match_score * 5, 20, colour, 2)

    draw_text("Customer mood: #{get_mood_name(result.mood)}", 305, 410, colour)
    draw_text("Gold earned: +#{result.payment}", 305, 445, GOLD)
    draw_text("Reputation change: #{result.reputation_change}", 305, 480)

    if check_game_end(game)
      draw_text("All three levels completed!", 305, 525, colour)
      draw_text("Final gold: #{game.player.gold} | Reputation: #{game.player.reputation}", 270, 560, GOLD)

      draw_button(225, 610, 260, 50, "Play Again", PURPLE)
      draw_button(515, 610, 260, 50, "Exit Game", GREY)
    else
      draw_text("Customers served: #{game.player.customers_served}/10", 305, 525)

      current_level = get_level(game.player.customers_served - 1)
      next_level = get_level(game.player.customers_served)

      if next_level > current_level
        draw_text("New level unlocked: Level #{next_level}", 305, 560, GOLD)
      end

      draw_button(300, 610, 400, 50, "Next Customer", PURPLE)
    end
  end

  # Ingredient card clicks

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

  # Mouse input

  def handle_click(game, mx, my)
    if game.screen != GameScreen::RESULTS
      if handle_ingredient_click(game, mx, my)
        return
      end

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

    case game.screen
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
        game.message = "Returned to the ingredient shop."

      elsif clicked?(mx, my, 555, 655, 410, 45)
        serve_potion(game)
      end

    when GameScreen::RESULTS
      if check_game_end(game)
        if clicked?(mx, my, 225, 610, 260, 50)
          @game = create_game_data
          @ingredient_page = 0
        elsif clicked?(mx, my, 515, 610, 260, 50)
          close
        end
      elsif clicked?(mx, my, 300, 610, 400, 50)
        game.potion = Potion.new
        game.message = "Prepare for your next customer."
        choose_next_customer(game)
        game.screen = GameScreen::SHOP
        @ingredient_page = 0
      end
    end
  end

  # Gosu events

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

  def draw
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, BACKGROUND, -1)

    draw_header(@game)

    case @game.screen
    when GameScreen::SHOP
      draw_shop(@game)
    when GameScreen::BREWING
      draw_brewing(@game)
    when GameScreen::RESULTS
      draw_results(@game)
    end

    draw_message(@game)
  end
end

AlchemistApp.new.show
