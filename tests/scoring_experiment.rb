# Reproducible scoring comparison using the actual game data and mix algorithm.
# This script reuses the headless Gosu stand-in provided by test_game.rb.
require_relative 'test_game'
require 'csv'

participants = create_game_data
rows = []
participants.customers.select.with_index { |_, i| [0, 3, 6].include?(i) }.each do |customer|
  count = customer.difficulty + 1
  combinations = (0...participants.ingredients.size).to_a.repeated_combination(count)
  results = combinations.map do |indices|
    potion = mix_ingredients(participants.ingredients, indices)
    [calculate_match_score(potion, customer), indices.map { |i| participants.ingredients[i].name }.join(' + '), potion.properties.join('/')]
  end
  results.sort_by { |score, recipe, _properties| [-score, recipe] }.first(5).each_with_index do |(score, recipe, properties), rank|
    rows << [customer.name, count, rank + 1, recipe, properties, get_customer_targets(customer).join('/'), score]
  end
end
path = File.expand_path('../docs/scoring_experiment.csv', __dir__)
CSV.open(path, 'w') do |csv|
  csv << ['Customer', 'Ingredients', 'Rank', 'Combination', 'Potion Heat/Calm/Energy/Bitterness', 'Target Heat/Calm/Energy/Bitterness', 'Match Percent']
  rows.each { |row| csv << row }
end
puts "Experiment saved: #{path} (#{rows.length} recipes)"
rows.each { |row| puts "#{row[0]} rank #{row[2]}: #{row[6]}% | #{row[3]}" if row[2] == 1 }
