
require 'gosu'

# Alchemist's Apothecary

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
                :result, :player
end

# Read ingredients from the text file

def load_ingredients(filename)
  ingredients = []

  if !File.exist?(filename)
    puts "Ingredient file not found."
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

# Read customers from the text file

def load_customers(filename)
  customers = []

  if !File.exist?(filename)
    puts "Customer file not found."
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

# Create initial game data

def create_game_data

  game = GameData.new

  game.ingredients = load_ingredients("ingredients.txt")
  game.customers = load_customers("customers.txt")

  game.screen = GameScreen::SHOP
  game.cauldron = []
  game.potion = Potion.new
  game.result = Result.new
  game.current_customer = nil

  player = Player.new

  player.gold = 100
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

  return game
end

# Main game window

class AlchemistApp < Gosu::Window

  def initialize
    super(1000, 760)

    self.caption = "Alchemist's Apothecary"

    @title_font = Gosu::Font.new(40)
    @font = Gosu::Font.new(25)

    @game = create_game_data

    puts "Ingredients loaded: #{@game.ingredients.length}"
    puts "Customers loaded: #{@game.customers.length}"
    puts "Starting gold: #{@game.player.gold}"
    puts "Game data loaded successfully."

  end

  def needs_cursor?
    return true
  end

  def update
  end

  def draw

    Gosu.draw_rect(
      0, 0, 1000, 760,
      Gosu::Color.rgb(23, 25, 35), 0
    )

    @title_font.draw_text(
      "ALCHEMIST'S APOTHECARY",
      50, 40, 1, 1, 1,
      Gosu::Color.rgb(235, 193, 112)
    )

    @font.draw_text(
      "Gold: #{@game.player.gold}",
      50, 110, 1
    )

    @font.draw_text(
      "Reputation: #{@game.player.reputation}",
      300, 110, 1
    )

    @font.draw_text(
      "Available Ingredients",
      50, 180, 1
    )

    index = 0

    while index < @game.ingredients.length

      ingredient = @game.ingredients[index]

      y = 240 + index * 65

      Gosu.draw_rect(
        50, y, 35, 35,
        ingredient.colour, 1
      )

      @font.draw_text(
        ingredient.name,
        110, y, 2
      )

      @font.draw_text(
        "Cost: #{ingredient.cost} gold",
        400, y, 2
      )

      @font.draw_text(
        "Owned: #{@game.player.inventory[index]}",
        700, y, 2
      )

      index += 1

    end

    @font.draw_text(
      "Customers loaded: #{@game.customers.length}",
      50, 690, 1
    )

  end

  def button_down(id)

    if id == Gosu::KB_ESCAPE
      close
    else
      super
    end

  end

end

AlchemistApp.new.show
