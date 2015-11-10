#!/usr/bin/ruby -w
# coding: utf-8

require_relative 'deck_manager.rb'



def main
  # todo: handle settings better
  $History = 2
  $defaultDelay = 1
  $Noise = 0.2
  $optimalStreak = 5
  $Magic = 2
  $Adventure = 0.3

  dm = DeckManager.new('backup_data.yml')
  loop do
    puts dm.getPrompt
    print ">> "
    x = gets[0...-1]
    if x == "quit"
      dm.closeEverything
      puts "ნახვამდის!"
      return
    else
      response = dm.takeAnswer(x)
      puts response if response
    end
  end
end


main
