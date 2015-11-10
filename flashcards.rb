#!/usr/bin/ruby -w
# coding: utf-8

require_relative 'deck_manager.rb'

# all the work goes into deck_manager


def main
  # TODO: handle settings better
  $History = 7 # minimum spacing between cards from the same word
  $defaultDelay = 1 # default long-term delay, in days
  $Noise = 0.2 # noise in assigning long-term duedates
  $optimalStreak = 5 # how long should we go before switching categories?
  $Magic = 2 # affects the desired size of CardManager's queue
  $Adventure = 0.3 # percentage of novel cards to show the user

  # load data from data.yml
  dm = DeckManager.new('data.yml')
  loop do
    puts dm.getPrompt
    print ">> "
    x = gets[0...-1] # discard trailing \n
    if x == "quit"
      dm.closeEverything
      puts "ნახვამდის!" # "goodbye!" ქართულად
      return
    else
      response = dm.acceptAnswer(x) # response might be nil
      puts response if response
    end
  end
end


main
