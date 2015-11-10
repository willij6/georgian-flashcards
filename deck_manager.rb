#!/usr/bin/ruby -w
# coding: utf-8

require 'psych'
require 'set'
require_relative 'structs.rb'

  

class Card
  attr_accessor :question, :answer, :parent, :type
end

class Word
  attr_accessor :category, :cards, :delay, :duedate, :seen
end




class CardSupplier
  def initialize(wordDatabase)
    @wordDatabase = wordDatabase
    @unseens = Hash.new
    @overdue = Hash.new
    @cardCounts = Hash.new
    @inPlay = Hash.new
    for c in wordDatabase.categories
      @unseens[c] = RandomRemoval.new
      @overdue[c] = RandomRemoval.new
      @cardCounts[c] = 0
      @inPlay[c] = 0
    end
    for w in wordDatabase.words
      c = w.category
      @cardCounts[c] += w.cards.size
      if w.seen
        if w.duedate <= wordDatabase.today
          @overdue[c].add(w)
        end
      else
        @unseens[c].add(w)
      end
    end
  end

  def cardsPlease
    bestCat = []
    bestNeed = 2
    for c in @wordDatabase.categories
      next if @unseens[c].size + @overdue[c].size == 0
      score = Math.log(1+@inPlay[c])/Math.log(1+@cardCounts[c])
      bestNeed = score if score < bestNeed
      bestCat << c if score == bestNeed
    end
    return [] if bestCat.size == 0
    bestCat.shuffle!
    category = bestCat[0]

    if @unseens[category].size == 0
      which = @overdue[category]
    elsif @overdue[category].size == 0
      which = @unseens[category]
    elsif rand < $Adventure
      which = @unseens[category]
    else
      which = @overdue[category]
    end

    word = which.pullRandom

    steal(word)
  end

  def steal(word)
    c = word.category
    @inPlay[c] += word.cards.size
    if @wordDatabase.confusion[word]
      for rival in @wordDatabase.confusion[word]
        c2 = rival.category
        @unseens[c2].remove(rival)
        @overdue[c2].remove(rival)
      end
    end
    [] + word.cards
  end

end




class CardScheduler
  def initialize (wordDatabase, cardSupplier)
    @wordDatabase = wordDatabase
    @cardSupplier = cardSupplier
    @pqueue = TimingQueue.new
    @queue = []
    @current = nil
    @history = []
    @time = 0
    @streak = 0
    @currentCat = nil
    @cardDelays = Hash.new

  end

  attr_reader :current

  def advanceTime
    @time += 1
    revealed = @pqueue.pullFrom(@time)
    revealed.shuffle!
    @queue.push(*revealed)
  end

  def loadMore
    howMany = 0
    for card in @queue
      next if historyConfusion(card) or historyRelated(card)
      howMany += 1
    end
    target = Integer(@wordDatabase.subcategories.size*$Magic+0.5)
    if howMany < target
      goal = target - howMany
      holding = []
      while holding.size < goal
        t = @cardSupplier.cardsPlease
        break if t.size == 0
        holding.push(*t)
      end
      holding.shuffle!
      for newcard in holding
        @queue << newcard
        if not newcard.parent.seen
          @cardDelays[newcard] = 5
        else
          @cardDelays[newcard] = Math.log(newcard.parent.delay)/Math.log(2)*5+10
        end
      end
    end
  end

  def empty?
    return @queue.empty? && @pqueue.empty? && @current == nil
  end

  def chooseCard
    return "no" if @current
    
    timeForAChange = (@streak >= $optimalStreak)
    ql = @queue.length
    bestCard = nil
    bestScore = 8*ql+1
    for i in 1..(@queue.length)
      card = @queue[-i]
      if(not card)
        puts "WHAT?"
      end
      score = i
      score += 4*ql if historyRelated(card)
      if timeForAChange and card.type == @currentCat
        score += 2*ql
      elsif !timeForAChange and card.type != @currentCat
        score += 2*ql
      end
      if score < bestScore
        bestScore = score
        bestCard = @queue.length - i
      end
    end

    if bestCard
      @current = @queue.delete_at(bestCard)
      if(@current.type == @currentCat)
        @streak += 1
      else
        @currentCat = @current.type
        @streak = 1
      end
    else
      @current = nil
    end
    @history.push(@current)
    @current
  end


  def stowCard(success)
    card = @current
    @current = nil
    @wordDatabase.flagSuccess(card,success)
    bad = Math.log(10)
    good = Math.log(2*@cardDelays[card])
    actual = good*success + bad*(1-success)
    actual = Math.exp(actual)
    @cardDelays[card] = actual
    duedate = @time + @cardDelays[card]*(rand + 0.5)
    duedate = Integer(duedate+0.5)
    @pqueue.enroll(card,duedate)
  end

  

  private
  
  def historyConfusion(card)
    for i in 1..$History
      next unless @history[-i]
      return true if @wordDatabase.confused(card,@history[-i])
    end
    false
  end

  def historyRelated(card)
    for i in 1..$History
      next unless @history[-i]
      return true if card.parent == @history[-i].parent
    end
    false
  end
  
end





class WordDatabase
  attr_reader :confusion, :categories, :subcategories, :words


  def unpack
    @words = words
    @categories = []
    @subcategories = []
    @qabank = Hash.new
    for word in words
      categories << word.category
      alt_cards = []
      word.cards.each do |type,card|
        @qabank[card.question] ||= []
        @qabank[card.question] << card.answer
        card.type = type
        card.parent = word
        alt_cards << card
        subcategories << type
      end
      word.cards = alt_cards
    end
    categories.uniq!
    subcategories.uniq!
    newConfusion = Hash.new
    for pair in @confusion
      first,second = pair
      newConfusion[first] ||= []
      newConfusion[first] << second
      newConfusion[second] ||= []
      newConfusion[second] << first
    end
    @confusion = newConfusion
  end

  def pack
    for word in words
      alt_cards = Hash.new
      for card in word.cards
        cc = Card.new
        cc.question = card.question
        cc.answer = card.answer
        alt_cards[card.type] = cc
      end
      word.cards = alt_cards
    end
    confList = []
    for i in 0...words.size
      next unless confusion[words[i]]
      for j in i+1...words.size
        if confusion[words[i]].include?(words[j])
          confList << [words[i],words[j]]
        end
      end
    end
    @confusion = confList
    {"words" => words, "confusion" => confusion}
  end
      
  
  def initialize(filename)
    @filename = filename
    @seenToday = Set.new
    @success = Hash.new
    data = Psych.load_file(filename)
    @words = data["words"]
    @confusion = data["confusion"]
    unpack

    @today = (Integer(Time.now) + Time.now.gmt_offset)/(24*3600)
  end

  def today
    @today
  end

  
  def confused(card1,card2)
    p1 = card1.parent
    p2 = card2.parent
    confusion[p1] and confusion[p1].include?(p2)
  end

  def flagSuccess(card, success)
    @success[card] ||= success
  end

  def handleWord(word)
    word.seen = true
    runningTotal = 0.0
    for card in word.cards
      unless @success[card]
        word.delay = $defaultDelay
        word.duedate = 1 + today
        return
      end
      runningTotal += @success[card]
    end
    unless word.delay
      word.delay = $defaultDelay
    end
    runningTotal /= word.cards.length # TODO: check for 0 cards
    word.delay = Math.exp(runningTotal*Math.log(2*word.delay)+(1-runningTotal)*Math.log($defaultDelay))
    word.duedate = Integer(0.5 + today + word.delay*Math.exp((rand-0.5)*$Noise))
  end
    
      
  def wrapUpCalculations
    for word in words
      next unless @seenToday.include?(word)
      handleWord word
    end
  end

  def flagSeen(card)
    @seenToday.add(card.parent)
    card.parent.seen = true
  end

  def legitimateAnswer(question,answer)
    return @qabank[question] && @qabank[question].include?(answer)
  end

  def closeEverything
    wrapUpCalculations
    data = pack
    File.open(@filename,'w') do |file|
      file.write(Psych.dump(data))
    end
  end
  
end



class DeckManager
  def initialize(filename)
    @wd = WordDatabase.new(filename)
    @cs = CardSupplier.new(@wd)
    @csched = CardScheduler.new(@wd,@cs)
    chooseCard
  end

  def noCards?
    return @csched.empty?
  end

  def getPrompt
    return "There are no more cards!" if noCards?
    return @card.question
  end

  def takeAnswer(a)
    return nil if noCards?
    if a == @card.answer
      @csched.stowCard(1.0)
      chooseCard
      return "Correct!"
    elsif @wd.legitimateAnswer(@card.question,a)
      return "I'm looking for something else"
    else
      rightAnswer = @card.answer
      @csched.stowCard(0.0)
      chooseCard
      return "Wrong answer (wanted: " + rightAnswer + ")"
    end
  end

  def closeEverything
    @wd.closeEverything
  end
    

  private
  def chooseCard
    @csched.advanceTime
    @csched.loadMore
    @card = @csched.chooseCard
    @wd.flagSeen(@card) if @card
  end
end