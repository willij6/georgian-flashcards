#!/usr/bin/ruby -w
# coding: utf-8


# run this, to remember what YAML looks like

require 'psych'

class Card
  attr_accessor :question, :answer, :parent, :type
end

class Word
  attr_accessor :category, :cards, :delay, :duedate, :seen
end

c1 = Card.new
c1.question = "dog"
c1.answer = "ძაღლი"
c2 = Card.new
c2.question = "ძაღლი"
c2.answer = "dog"
dog = Word.new
dog.category = "ka-nouns"
dog.cards = {"en->ka" => c1, "ka->en" => c2}

c1 = Card.new
c1.question = "cat"
c1.answer = "კატა"
c2 = Card.new
c2.question = "კატა"
c2.answer = "cat"
c3 = Card.new
c3.question = "cat's"
c3.answer = "კატის"
cat = Word.new
cat.category = "ka-nouns"
cat.cards = {"en->ka" => c1, "ka->en" => c2, "gen" => c3}

c1 = Card.new
c1.question = "red"
c1.answer = "წითელი"
c2 = Card.new
c2.question = "წითელი"
c2.answer = "red"
red = Word.new
red.category = "ka-adj"
red.cards = {"en->ka" => c1, "ka->en" => c2}

c1 = Card.new
c1.question = "mouse"
c1.answer = "თაგვი"
mouse = Word.new
mouse.category = "ka-nouns"
mouse.cards = {"en->ka" => c1}


data = {'words' => [dog,cat,red,mouse], 'confusion' => [[mouse,red]]}

puts(Psych.dump(data))
