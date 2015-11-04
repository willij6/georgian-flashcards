#!/usr/bin/ruby -w
# coding: utf-8

require 'psych'
require 'set'

class SkewNode
  attr_accessor :left, :right, :priority, :value
  
  def initialize(priority,value)
    @priority = priority
    @value = value
    @left = @right = nil
  end
end

def merge(node1,node2)
  if node1
    if node2
      if node1.priority > node2.priority
        node1,node2 = node2,node1
      end
      node1.right = merge(node1.right,node2)
      node1.left,node1.right = node1.right,node1.left
    end
    node1
  else
    node2
  end
end


class CardQueue
  def initialize
    @root = nil
  end

  def pullFrom(time)
    holding = []
    while @root and @root.priority <= time
      holding.push(@root.value)
      @root = merge(@root.left, @root.right)
    end
    holding
  end

  def empty?
    not @root
  end

  def enroll(card,time)
    newnode = SkewNode.new(time,card)
    @root = merge(@root,newnode)
  end
end

class RandomRemoval
  def initialize
    @content = []
    @indices = Hash.new
  end

  def include?(x)
    @indices[x] # huh
  end

  def size
    @content.size
  end

  def add(x)
    unless include?(x)
      @indices[x] = @content.size
      @content.push(x)
    end
  end

  def remove(x)
    if include?(x)
      ind = @indices[x]
      ind2 = @content.size - 1
      swap(ind,ind2)
      pop
    end
  end

  def pullRandom
    return nil if size == 0
    ind = rand(size)
    swap(ind,size-1)
    removeEnd
  end

  private
  def swap(index1,index2)
    if index1==index2
      return
    end
    @content[index1],@content[index2] = @content[index2],@content[index1]
    @indices[@content[index1]] = index1
    @indices[@content[index2]] = index2
  end

  def removeEnd
    @indices.delete(@content[-1])
    @content.pop
  end

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
    @pqueue = CardQueue.new
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


class Card
  attr_accessor :question, :answer, :parent, :type
end

class Word
  attr_accessor :category, :cards, :delay, :duedate, :seen
end



# c1 = Card.new
# c1.question = "dog"
# c1.answer = "ძაღლი"
# c2 = Card.new
# c2.question = "ძაღლი"
# c2.answer = "dog"
# dog = Word.new
# dog.category = "ka-nouns"
# dog.cards = {"en->ka" => c1, "ka->en" => c2}
# dog.seen = false

# c1 = Card.new
# c1.question = "cat"
# c1.answer = "კატა"
# c2 = Card.new
# c2.question = "კატა"
# c2.answer = "cat"
# c3 = Card.new
# c3.question = "cat's"
# c3.answer = "კატის"
# cat = Word.new
# cat.category = "ka-nouns"
# cat.cards = {"en->ka" => c1, "ka->en" => c2, "gen" => c3}
# cat.seen = false

# c1 = Card.new
# c1.question = "red"
# c1.answer = "წითელი"
# c2 = Card.new
# c2.question = "წითელი"
# c2.answer = "red"
# red = Word.new
# red.category = "ka-adj"
# red.cards = {"en->ka" => c1, "ka->en" => c2}
# red.seen = false

# data = {'words' => [dog,cat,red], 'confusion' => []}

# puts(Psych.dump(data))



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
    confusion[p1] and confusion[p1].include?[p2]
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
  
end



def main
  $History = 2
  $defaultDelay = 1
  $Noise = 0.2
  $optimalStreak = 5
  $Magic = 2
  $Adventure = 0.3
  
  wd = WordDatabase.new('data.yml')
  cs = CardSupplier.new(wd)
  csched = CardScheduler.new(wd,cs)
  loop do
    csched.loadMore
    card = csched.chooseCard
    if csched.empty?
      loop do
        puts "There are no more cards!"
        if gets == "quit\n"
          puts "ნახვამდის!"
          wd.wrapUpCalculations
          data = wd.pack
          File.open('data.yml','w') do |file|
            file.write(Psych.dump(data))
          end
          return
        end
      end
    end
    if card
      wd.flagSeen(card)
      answered = false
      until answered
        puts card.question + "?"
        a = gets
        a = a[0...(a.length-1)] # remove trailing newline?!
        if a == "quit"
          puts "ნახვამდის!"
          wd.wrapUpCalculations
          data = wd.pack
          File.open('data.yml','w') do |file|
            file.write(Psych.dump(data))
          end
          return
        elsif a == card.answer
          puts "That's right!"
          csched.stowCard(1.0)
          answered = true
        elsif wd.legitimateAnswer(card.question,a)
          puts "Okay, but what else?"
        else
          puts "Sorry, wrong answer"
          puts "Right answer was " + card.answer
          puts "Yet you typed " + a + ", or whatever"
          csched.stowCard(0.0)
          answered = true
        end
      end
    end
    csched.advanceTime
  end
end



















# ##################################################################




# def setToday
#   $TODAY = (Integer(Time.now) + Time.now.gmt_offset)/(24*3600)
# end



# # premature optimization is the root of all evil



# class Algorithm
#   # @words
#   # @wordDelays
#   # @wordDues
#   # @cards
#   # @cardDelays
#   # @history
#   # @round
#   # @queue
#   # @upcoming
#   # @confused


#   def confused(word1,word2)
#     @confused[word1] and @confused[word1].include?(word2)
#   end

#   def confusedAgainstHistory(card)
#     for i in 1..$HISTORY
#       next if not @history[-i]
#       return true if confused(card.parent,@history[-i].parent)
#     end
#     return false
#   end

#   def conjugateOfHistory(card)
#     for i in 1..$HISTORY
#       next if not @history[-i]
#       return true if card.parent == @history[-i].parent
#     end
#     return false
#   end

#   def numSubcats
#     temp = Hash.new(0)
#     for c in @cards
#       temp[c.type] += 1
#     end
#     temp.size
#   end

#   def pullFromPriority
#     holding = []
#     @upcoming.delete_if do |x|
#       duedate,card = x
#       if duedate<=@round
#         holding.push(card)
#         true
#       else
#         false
#       end
#     end
#     holding.shuffle!
#     @queue.unshift(holding)
#   end

#   def confusedVsCollection(word,words)
#     for word2 in words
#       return true if confused(word,word2)
#     end
#     return false
#   end

#   def loadSomeMore(needed)
#     cardCounts = Hash.new
#     inPlayCts = Hash.new
#     inPlayCards = Hash.new(false)
#     for card in @cards
#       cardCounts[card.parent.category] += 1
#     end
#     for card in @queue
#       inPlayCts[card.parent.category] += 1
#       inPlayCards[card.parent] = true
#     end
#     for card in @upcoming
#       inPlayCts[card.parent.category] += 1
#       inPlayCards[card.parent] = true
#     end

#     holding = []
#     while holding.size < needed
#       eligibleCats = []
#       unseen = Hash.new
#       overdue = Hash.new
#       for w in @words
#         next if w.cards.size == 0
#         next if inPlayCards.include?(w)
#         next if confusedVsCollection(w,inPlayCards)
#         if w.seen
#           if w.duedate <= $TODAY
#             overdue[w.category] ||= []
#             overdue[w.category] << w
#           else
#             next
#           end
#         else
#           unseen[w.category] ||= []
#           unseen[w.category] << w
#         end
#         if not eligibleCats.include?(w.category)
#           eligibleCats.push(w.category)
#         end
#       end
#       break if eligibleCats.size == 0
#       bestVal = 2
#       for cat in eligibleCats
#         score = Math.log(1+inPlayCts[cat])/Math.log(1+cardCounts[cat])
#         if(score < bestVal)
#           bestVal = score
#           bestCat = cat
#         end
#       end
#       if overdue[bestCat].size == 0
#         which = unseen[bestCat]
#       elsif unseen[bestCat].size == 0
#         which = overdue[bestCat]
#       elsif rand(0) < $ADVENTURE
#         which = unseen[bestCat]
#       else
#         which = overdue[bestCat]
#       end
#       word = which[rand(which.size)]
#       holding.push(*word.card)
#     end
#     holding.shuffle!
#     @queue.push(*holding)
#   end
  



#   def streakAssess
#     category = nil
#     length = 0
#     i = 1
#     while i <= @history.size
#       next unless @history[-i]
#       if category
#         if category == @history[-i].type
#           length += 1
#         else
#           break
#         end
#       else
#         category = @history[-i].type
#         length = 1
#       end
#     end
#     return [category,length]
#   end
          
  

#   def chooseCardFromQueue

#     streakCat,streakLen = streakAsses
    
    
#     ql = @queue.size
#     return nil if ql == 0
#     bestIndex = -1
#     bestScore = 16*ql
#     for i in 0...ql
#       card = @queue[i]
#       next if confusedAgainstHistory(card)
#       priority = i
#       priority += 4*ql if conjugateOfHistory(card)
#       if(streakCat)
#         if (streakCat == card.type) != (streakLen < $DESIRED)
#           priority += 2*ql
#         end
#       end
#       if priority < bestScore
#         bestScore = priority
#         bestIndex = i
#       end
#     end
#     return bestIndex
#   end
    
      

#   def legitAnswer(question,answer)
#     for c in @cards
#       if c.question == question and c.answer == answer
#         return true
#       end
#     end
#     return false
#   end

#   def queryUser(card)
#     puts card.question
#     loop do
#       answ = gets
#       if answ == card.answer
#         puts "Correct!"
#         return 1.0
#       elsif legitAnswer(card.question,answ)
#         puts "Okay, but what else?"
#       else
#         puts "No, should be " + card.answer
#         return 0.0
#       end
#     end
#   end


#   def newDuedateAndDelay(card,success)
#     bad = Math.log(10)
#     good = Math.log(2*@cardDelays[card])
#     actual = good*success + bad*(1-success)
#     actual = Math.exp(actual)
#     @cardDelays[card] = actual
#     duedate = @round + @cardDelays[card]*(rand + 0.5)
#     duedate = Integer(duedate+0.5)
#     @upcoming.push([duedate,card])
#   end
  
#   def oneRound
#     @round += 1
#     pullFromPriority

#     unblocked = 0
#     for card in @queue
#       unblocked += 1 unless confusedAgainstHistory(card)
#     end
#     target = Integer($BLAH*numSubcats)
#     loadSomeMore(target-unblocked) if unblocked < target

#     choice = chooseCardFromQueue
#     if choice
#       choice = @queue.delete_at(choice)
#       choice.parent.seen = True
#       # todo, do something about duedates
#       success = queryUser(choice)
#       @firstAttempts[choice] ||= success
#       newDuedateAndDelay(choice,success)
#       @history.push(choice)
#     end
#   end

# end

      
      
    
  




