#!/usr/bin/env ruby

class UI
	def self.ask_for_player_names
		print "Enter players name seperated by comma: "
		gets.chomp.strip.split(/\s*,\s*/)
	end

	def self.display_round_number(round_number)
		puts
		puts "<<<<Round #{round_number}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
	end

	def self.display_player_name(player_name, in_the_game)
		puts
		puts "#{player_name}\'s turn"
		if !in_the_game
			puts "You must roll atleast #{Game::QUALIFICATION_POINT} points in one turn to qualify for the game."
		end
	end

	def self.display_last_round
		puts
		puts "<<<<Last Round>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
	end

	def self.rolled_no_scoring_dice
		puts
		puts "You rolled no scoring dice. Your turn is over"
	end

	def self.rolled_all_scoring_dice(roll_points, turn_points, dice_remaining)
		puts
		puts "You rolled #{roll_points} points giving you a total of #{turn_points} points for this turn. "
		puts "You rolled all scoring dice so you get to roll all dice again. So you get to roll all #{dice_remaining} dice again."
		print "Do you wish to roll again? [y/n]: "
		gets.chomp
	end

	def self.rolled_dice(roll_points, total_points, dice_remaining)
		puts
		puts "You rolled #{roll_points} points giving you a total of #{total_points} points for this turn."
		print "You have #{dice_remaining} dice remaining. Do you wish to roll again? [y/n]: "
		gets.chomp
	end

	def self.earned_points(turn_points, total_points)
		puts
		puts "You earned #{turn_points} points this turm. Your total point now is #{total_points}"
	end

	def self.display_final_score(players)
		puts
		puts "<<<<Final Score>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		puts
		players.each do |player|
			puts " #{player.name}: #{player.total_points}"
		end
		puts
	end
end

class Diceset
	attr_reader :total_dice
	attr_reader :scoring_dice
	attr_reader :non_scoring_dice
	attr_reader :points
	attr_reader :results

	def initialize(num_dice)
		@total_dice = num_dice
	end

	def roll
		@scoring_dice = 0
		@non_scoring_dice = 0
		@points = 0
		@results = []

		@total_dice.times { @results << rand(6) + 1 }

		1.upto(6) do |num|
			qty = @results.count(num)

			#Scoring for triplets
			if qty >=3
				@points += num == 1 ? 1000 : num * 100
				@scoring_dice += 3
				qty -= 3
			end

			#Scoring for single 1's
			if num == 1
				@points += qty * 100
				@scoring_dice += qty
			end

			#Scoring for single 5's
			if num == 5
				@points += qty * 50
				@scoring_dice += qty
			end
		end

		@non_scoring_dice = @total_dice - @scoring_dice
		@results
	end

	def all_scoring_dice?
		@scoring_dice == @total_dice ? true : false
	end

	def no_scoring_dice?
		@scoring_dice == 0 ? true : false
	end
end

class Player
	attr_reader :name
	attr_reader :finished
	attr_reader :total_points

	def initialize(name)
		@name = name
		@in_the_game = false
		@finished = false
		@total_points = 0
	end

	def take_turn
		roll_point = 0
		turn_points = 0
		dice_remaining = Game::DICE_IN_USE

		UI.display_player_name(@name, @in_the_game)

		loop do
			dice = Diceset.new(dice_remaining)
			dice.roll
			roll_points = dice.points
			turn_points += roll_points

			if dice.no_scoring_dice?
				UI.rolled_no_scoring_dice
				break
			elsif dice.all_scoring_dice?
				dice_remaining = Game::DICE_IN_USE
				answer = UI.rolled_all_scoring_dice(roll_points, turn_points, dice_remaining)
			else
				dice_remaining = dice.non_scoring_dice
				answer = UI.rolled_dice(roll_points, turn_points, dice_remaining)
			end

			if answer.downcase == "n"
				if !@in_the_game
					if turn_points < Game::QUALIFICATION_POINT
						turn_points = 0
					else
						@in_the_game = true
					end
				end
				@total_points += turn_points

				if @total_points >= Game::WINNING_POINT
					@finished = true
				end

				UI.earned_points(turn_points, @total_points)
				break
			end
		end
	end
end

class Game
	DICE_IN_USE = 5
	QUALIFICATION_POINT = 300
	WINNING_POINT = 3000

	def initialize
		@players = []
		@round = 1
		@last_round = false

		start_game
	end

	def start_game
		UI.ask_for_player_names.each do |name|
			@players << Player.new(name)
		end

		until @last_round
		UI.display_round_number(@round)
			@players.each do |player|
				player.take_turn

				if player.finished
					@last_round = true
					break
				end
			end
			@round += 1
		end

		if @last_round
			UI.display_last_round

			@players.each do |player|
				unless player.finished
					player.take_turn
				end
			end
		end

		UI.display_final_score(@players)
	end
end

Game.new