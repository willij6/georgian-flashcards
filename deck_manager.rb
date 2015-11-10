#!/usr/bin/ruby -w
# coding: utf-8

require 'psych' # reading and writing YAML
require 'set' # hash set
require_relative 'structs.rb' # some data

# TODO: settings are currently stored in the global variables
# $Adventure, $Magic, $optimalStreak, $defaultDelay, and $Noise





# the DeckManager class is the outward-facing facade for
# most of the program, specifically the code that:
# * loads and saves the database of cards
# * chooses which order to present the cards to the user
# * assesses user responses to questions
# * updates the difficulty levels
#
# What's missing is the I/O code to interact with the user,
# and special commands that the main program loop should catch,
# like exit/quit and help.
#
# Example Usage:
# dm = DeckManager('cards.yml')
# dm.noCards? # => false
# dm.getPrompt # => 'გამარჯობათ'
# dm.acceptAnswer "hello" # => "Correct!"
# dm.noCards? # => false
# dm.getPrompt # => 'to read'
# dm.acceptAnswer 'დაწერა' # => "Incorrect (wanted: კითხვა)"
# dm.closeEverything
#
class DeckManager

  # Internally, things are managed using three objects,
  # a WordDatabase, a CardSupplier, and a CardScheduler
  #
  # The WordDatabase loads and saves the database,
  # and updates the long-term difficulties of words.
  #
  # The CardSupplier and CardScheduler together determine
  # the order in which cards are presented to the user
  #
  # CardSupplier provides on-demand cards to CardScheduler
  # CardScheduler cycles through an ever increasing pool of cards,
  # using spaced repetition on a small scale

  # The three objects are stored in instance variables @wd, @cs, and @csched
  # there's also a @card instance variable, which stores the card being
  # _currently_ displayed to the user
  # TODO: this might be the same thing as  @csched.current
  

  # create a DeckManager using the data in the
  # given file and start it up
  def initialize(filename)
    @wd = WordDatabase.new(filename)
    @cs = CardSupplier.new(@wd)
    @csched = CardScheduler.new(@wd,@cs)
    chooseCard # loads the first few cards and selects the current card
  end

  # have we run out of cards?
  def noCards?
    return @csched.empty?
  end

  # what question should be displayed to the user?
  def getPrompt
    return "There are no more cards!" if noCards?
    return @card.question
  end

  # accept an answer to the current question from the user
  # return a string with a comment on the correctness of the answer
  # or nil if we have nothing to say
  # TODO: maybe we should return a status code instead?
  def acceptAnswer(a)
    return nil if noCards?
    if a == @card.answer
      @csched.stowCard(1.0) # pass on the news to the CardScheduler
      chooseCard # choose the next card
      return "Correct!"
    elsif @wd.legitimateAnswer(@card.question,a)
      return "I'm looking for something else"
    else
      rightAnswer = @card.answer
      @csched.stowCard(0.0) # pass on the news to the CardScheduler
      chooseCard # choose the next card
      return "Wrong answer (wanted: " + rightAnswer + ")"
    end
  end

  # called at the end of session.
  # Saves all the data, updating difficulty levels and duedates of
  # cards based on the user's performance today
  def closeEverything
    @wd.closeEverything
  end
    

  private
  def chooseCard

    # CardScheduler isn't guaranteed to return a card each round,
    # so we advance time until it does
    @card = nil
    until @card
      # advance the CardScheduler's internal clock
      @csched.advanceTime
      # if necessary, send cards from the CardSupplier to the CardScheduler
      @csched.loadMore
      # if there's really no cards, accept defeat
      break if @csched.empty?
      # choose the actual card (this may return nil)
      @card = @csched.chooseCard
    end
    # tell the WordDatabase that the card has been seen
    # (this forces the card to appear soon in the future, rather than
    #  be forgotten)
    @wd.flagSeen(@card) if @card
  end
end



# structures for cards and words
# A single word might have multiple cards associated with it,
# e.g. ძაღლი->dog and dog->ძაღლი.

class Card
  attr_accessor :question, :answer, :parent, :type
  # @parent is the Word that owns this card
  # @type is a string describing what type of question this is
  #
  # Questions of similar type are grouped together, to avoid
  # the distraction of context switching
  # (as well as the annoyance of switching IMEs)
end

class Word
  attr_accessor :category, :cards, :delay, :duedate, :seen
  # @category is something like "noun","verb","adjective",
  #             "Korean noun","German preposition",whatever
  # the CardSupplier tries to make sure all categories are represented
  # @cards is an Array of Cards
  # @delay, @duedate, and @seen are used by WordDatabase
  # to manage the long-term scheduling of cards (across days)
  # @delay is a proxy for how well the user knows the card:
  #        it counts how many days we should wait between
  #        before showing the user the card again, assuming she gets it right
  # @duedate is the day number of when the card should next appear
  # @seen is whether or not the card has ever been seen by the user
  #      if @seen is false, then @delay and @duedate won't be defined
end




# The CardSupplier is responsible for providing a steady stream
# of cards to the CardScheduler.  Its goals are to balance the
# different categories of words, introduce new (i.e. "unseen")
# cards, and to ensure that if ONE card associated to a word
# appears, then so do all the OTHER cards associated with this word.
#
# The CardSupplier also tries to ensure that in a given session,
# two _confused_ words won't both appear.
# (there is a user-defined list of confused pairs of words)
#
# After creating a CardSupplier (which has a link back to the WordDatabase),
# the CardScheduler can ask for cards by calling cardsPlease, which returns
# a list of cards--either all the cards associated to a carefully chosen word,
# OR an empty list if we've somehow run out of cards
#
# CardScheduler can also call steal(word), where word is a Word object,
# and this forces CardSupplier to yield the associated cards
class CardSupplier

  # Internally, here's what's going on.
  # A word can either be
  # * already provided to the CardScheduler (aka "in play")
  # * in one of several pools
  # * unavailable for today's session
  #
  # For each category of word, there are two pools:
  # * the new "unseen" cards that the user has yet to learn
  # * the cards that are overdue
  #
  # When asked for cards, the CardSupplier first chooses
  # the category of word, in an attempt to balance the categories.
  # (This balancing requires a count of how many _cards_ are in each category)
  # It then chooses which of the two pools to choose from,
  # based on the $Adventure setting
  #
  # It then chooses randomly from the corresponding pool
  # The chosen word is withdrawn from the pool, and its cards
  # are passed back to the caller.
  #
  # Along the way, all words confused with the chosen word
  # are discarded from their corresponding pools


  

  # create a CardSupplier. It needs the wordDatabase,
  # since this is the source of cards
  def initialize(wordDatabase)
    @wordDatabase = wordDatabase
    @unseens = Hash.new # the pools of unseen cards, sorted by category
    @overdue = Hash.new # the pools of overdue cards, sorted by category
    @cardCounts = Hash.new # how many cards are in each category?
    @inPlay = Hash.new # how many cars are _in play_ in each category?
                       # in play means: already passed to the CardScheduler
    for c in wordDatabase.categories
      @unseens[c] = RandomRemovalSet.new
      @overdue[c] = RandomRemovalSet.new
      @cardCounts[c] = 0
      @inPlay[c] = 0
    end
    for w in wordDatabase.words
      c = w.category
      @cardCounts[c] += w.cards.size
      if w.seen
        if w.duedate <= wordDatabase.today
          @overdue[c].add(w)
        end # otherwise, forget about that word
      else
        @unseens[c].add(w)
      end
    end
  end


  def cardsPlease
    # step 1: choose the category
    # we score each category based on log(1+inPlay)/log(1+cardCounts)
    # the lowest score is the most needy
    # Logarithms ensure that small categories are represented, but don't dominate
    bestCat = [] # a list of the top ones
    bestNeed = 2
    for c in @wordDatabase.categories
      # skip categories where both pools are empty
      next if @unseens[c].size + @overdue[c].size == 0
      score = Math.log(1+@inPlay[c])/Math.log(1+@cardCounts[c])
      bestNeed = score if score < bestNeed
      bestCat << c if score == bestNeed
    end
    return [] if bestCat.size == 0 # well, guess there are no more cards
    bestCat.shuffle! # shuffle the list, to be fair
    category = bestCat[0] # TODO: that was suboptimal

    # step 2: There are two pools of words for this category.
    #         Choose which to draw from.
    if @unseens[category].size == 0
      which = @overdue[category] # no choice
    elsif @overdue[category].size == 0
      which = @unseens[category] # no choice
    elsif rand < $Adventure # else flip a coin
      which = @unseens[category]
    else
      which = @overdue[category]
    end

    # Step 3: choose the word
    word = which.pullRandom

    # Step 4: flag that it's in play, remove all confusables
    steal(word)
  end

  # pull a word into play, updating state accordingly
  # return the set of associated cards
  def steal(word)
    c = word.category
    # update the count of in-play cards in each category
    @inPlay[c] += word.cards.size
    if @wordDatabase.confusion[word]
      # if some words are confused with the chosen one,
      # forget about those other words, for today
      for rival in @wordDatabase.confusion[word]
        c2 = rival.category
        @unseens[c2].remove(rival)
        @overdue[c2].remove(rival)
      end
    end
    [] + word.cards # return a _copy_ of the collection
  end

end




# the CardScheduler chooses in which order to present
# to the user, the cards it receives from the CardSupplier
class CardScheduler

  # the CardScheduler runs spaced repetition on a small
  # scale.  It uses the rounds of interaction with the
  # user as a proxy for time.
  # When there's a shortage of upcoming cards, it
  # asks the CardSupplier for some more.
  # occasionally it's forced to skip rounds
  
  def initialize (wordDatabase, cardSupplier)
    @wordDatabase = wordDatabase
    @cardSupplier = cardSupplier
    @pqueue = TimingQueue.new # list of cards scheduled for the future
    @queue = [] # cards that are overdue
    @current = nil # the card _currently_ presented to the user
    @history = [] # recent cards (or nils, for skipped rounds)
    @time = 0 # the internal clock
    # @streak counts how many rounds we've been doing cards
    # of a given type.  It's used to decide whether we want to
    # continue the streak, or change things up
    @streak = 0
    @currentCat = nil # what IS the current type of card?
    @cardDelays = Hash.new # proxy for the short-term difficulty level of the cards

  end

  attr_reader :current

  # tell the CardScheduler that time should advance
  def advanceTime
    @time += 1
    # some cards will now reach their duedate
    revealed = @pqueue.pullFrom(@time)
    revealed.shuffle!
    @queue.push(*revealed)
  end

  # Check whether we have an upcoming shortage of cards,
  # and ask the CardSupplier for more if so
  def loadMore
    # step 1: count how many "eligible" cards are in the queue
    # cards are ineligible if they're easily confused with
    # cards we saw recently, or if they come from the same Word
    # as cards we saw recently.
    # (e.g., if we just showed the user the question
    #  "კატა -> cat", we shouldn't immediately ask for
    #  "cat -> კატა"; that's unhelpful)
    howMany = 0
    for card in @queue
      next if historyConfusion(card) or historyRelated(card)
      howMany += 1
    end
    # step 2: magic formula for how many cards we'd LIKE to have
    target = Integer(@wordDatabase.subcategories.size*$Magic+0.5)
    if howMany < target
      goal = target - howMany # we want this many cards
      holding = [] # store the new cards here.  (will shuffle later)
      while holding.size < goal
        t = @cardSupplier.cardsPlease
        break if t.size == 0 # cardSupplier ran out of cards
        holding.push(*t)
      end
      holding.shuffle!
      # next, add these new cards into the queue
      for newcard in holding
        @queue << newcard
        # we also need to assign each card a difficulty level
        if not newcard.parent.seen
          @cardDelays[newcard] = 5
        else
          @cardDelays[newcard] = Math.log(newcard.parent.delay)/Math.log(2)*5+10
        end
      end
    end
  end

  # return true if CardSupplier hasn't been given any cards yet
  def empty?
    return @queue.empty? && @pqueue.empty? && @current == nil
  end

  # select the card, assuming none is currently selected
  def chooseCard
    return "no" if @current # TODO: do something better

    # should we change up the flavor of questions we're giving the user?
    timeForAChange = (@streak >= $optimalStreak)
    
    # look through the queue and choose the "best" card
    # top priority: avoid words we saw recently
    # second priority: maintain or break the streak
    # last priority: choose someone near the start of the queue
    ql = @queue.length
    bestCard = nil
    bestScore = 8*ql+1 # lower scores are better
    for i in 0...(@queue.length)
      card = @queue[i]
      next if historyConfusion(card) # keep confused cards apart!
      score = i # penalize for being later in the queue
      # penalize for: we just saw this word
      score += 4*ql if historyRelated(card)
      # penalize for making or breaking the streak?
      if timeForAChange and card.type == @currentCat
        score += 2*ql
      elsif !timeForAChange and card.type != @currentCat
        score += 2*ql
      end
      if score < bestScore
        bestScore = score
        bestCard = i
      end
    end

    if bestCard
      @current = @queue.delete_at(bestCard)
      # update the card-type streak counter
      if(@current.type == @currentCat)
        @streak += 1
      else
        @currentCat = @current.type
        @streak = 1
      end
    else
      @current = nil
    end
    # add the card to history, or nil if nothing could be done!
    @history.push(@current)
    @current
  end


  # record success or failure for the current card,
  # and squirrel it away into a queue
  # success can be any floating point number between 0 (failure) and 1 (success)
  # Ultimately, I'd like the user to flag a card as half-success, if they
  # feel non-confident in their answer
  def stowCard(success)
    card = @current
    @current = nil
    # notify the WordDatabase
    # (it cares about the first success or failure on each card)
    @wordDatabase.flagSuccess(card,success)
    # take a weighted geometric mean of 10 and 2*@cardDelays[card],
    # and make this the new @cardDelays[card]
    bad = Math.log(10)
    good = Math.log(2*@cardDelays[card])
    actual = good*success + bad*(1-success)
    actual = Math.exp(actual)
    @cardDelays[card] = actual

    # put the card into the timing queue, with the delay
    # based on the delay we just chose, plus noise
    duedate = @time + @cardDelays[card]*(rand + 0.5)
    duedate = Integer(duedate+0.5)
    @pqueue.enroll(card,duedate)
  end

  

  private

  # return true if card is _confusable_ with a word
  # the user recently saw
  def historyConfusion(card)
    for i in 1..$History
      next unless @history[-i]
      return true if @wordDatabase.confused(card,@history[-i])
    end
    false
  end

  # return true if card comes from the same word
  # as any cards we saw recently
  def historyRelated(card)
    for i in 1..$History
      next unless @history[-i]
      return true if card.parent == @history[-i].parent
    end
    false
  end
  
end




# the WordDatabase is in charge of file/io,
# maintaining all the static data about cards,
# and long range scheduling.
#
# It doesn't care about the individual details
# of card scheduling within a session, though it
# does want to know how well the user did on each
# card (to adjust long-term timing)
class WordDatabase

  # @categories is an Array with the names of
  # the categories of Words.
  # @subcategories is an Array with the names of
  # the categories of Cards.
  # @words is the Array of Words
  # @confusion tracks which pairs of words are confused
  attr_reader :confusion, :categories, :subcategories, :words

  # additionally,
  # @qabank stores a big list of all the question-answer pairs
  #     this allows us to give the user a second chance, if she entered
  #     an answer that was technically correct, but not the answer
  #     we were expecting
  # @today stores today's day number
  # @seenToday is a set of all cards the user has seen
  # @success keeps track of initial success/fail on each card
  # @filename remembers where the data is stored

  private
  
  # all the data is stored differently as YAML than we'd like to use it
  # pack and unpack convert between the more compact form (stored as YAML)
  # and the expanded form (used while the program is running)
  
  def unpack
    @categories = []
    @subcategories = []
    @qabank = Hash.new
    # loop through words and cards, filling in all these
    # and adjusting the parent and type links
    for word in words
      categories << word.category
      # cards are in a Hash (keys are type)
      # convert to a flat array
      alt_cards = [] # will become word.cards
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
    # clean up duplicates in the categories and subcategories lists
    categories.uniq!
    subcategories.uniq!

    # confusion starts as a list of pairs of Cards; we want to
    # convert it into a Hash map from Cards to lists of Cards
    newConfusion = Hash.new # this will become @confusion later on
    for pair in @confusion
      first,second = pair
      # add links both ways!  Confusion is symmetric
      newConfusion[first] ||= []
      newConfusion[first] << second
      newConfusion[second] ||= []
      newConfusion[second] << first
    end
    @confusion = newConfusion
  end

  # undoes most of the changes of unpack
  # In particular, it sets @words and @confusion
  # to something appropriate to store as YAML,
  # It returns the exact thing that should be stored.
  def pack
    for word in words
      # convert the list of cards to a map (a Hash)
      alt_cards = Hash.new
      for card in word.cards
        cc = Card.new # easiest way to delete the parent and type links
        cc.question = card.question
        cc.answer = card.answer
        alt_cards[card.type] = cc
      end
      word.cards = alt_cards
    end
    # we need to convert @confusion from a map to a list
    confList = []
    for i in 0...words.size
      next unless confusion[words[i]]
      # the confusion relation is symmetric, but we don't want
      # to record everything twice, so we need to be careful
      for j in i+1...words.size
        if confusion[words[i]].include?(words[j])
          confList << [words[i],words[j]]
        end
      end
    end
    @confusion = confList
    {"words" => words, "confusion" => confusion} # store this as YAML!
  end

  public

  # create a WordDatabase from the given file
  def initialize(filename)
    @filename = filename
    @seenToday = Set.new # tracks which cards were ever shown to the user today
    @success = Hash.new # tracks the initial success/failure of each card
    
    data = Psych.load_file(filename)
    @words = data["words"]
    @confusion = data["confusion"]
    unpack # fixes the format of @words and @confusion

    @today = (Integer(Time.now) + Time.now.gmt_offset)/(24*3600)
  end

  # return today's day number, which CardSupplier cares about to decide
  # whether cards are past due
  def today
    @today
  end


  # tell whether two cards come from easily confusable words
  def confused(card1,card2)
    p1 = card1.parent
    p2 = card2.parent
    confusion[p1] and confusion[p1].include?(p2)
  end

  # CardScheduler calls this to record the success
  # or failure on a given card.  We make a note of the
  # _first_ success or fail on each card.
  def flagSuccess(card, success)
    # @success[card] already exists,
    # this does nothing.
    @success[card] ||= success
  end


  private

  # update the difficulty stats on each card
  def wrapUpCalculations
    for word in words
      next unless @seenToday.include?(word)
      handleWord word
    end
  end

  
  # update the difficulty stats on a specific card
  # this should be called ONLY on cards that were seen today
  def handleWord(word)
    word.seen = true

    # calculate the weighted average of successes on the associated cards
    runningTotal = 0.0
    for card in word.cards
      # if the card was _partially_ seen, make sure we see it again
      # immediately
      unless @success[card]
        word.delay = $defaultDelay
        word.duedate = 1 + today
        return
        # TODO: this ruins progress on cards we should have mastered!
      end
      runningTotal += @success[card]
    end
    successFraction = runningTotal / word.cards.length # TODO: check for 0 cards


    # assign a default value of word.delay, in case it's currently unassigned
    unless word.delay
      word.delay = $defaultDelay
    end

    # use the success fraction to calculate a weighted geometric mean
    word.delay = Math.exp(successFraction*Math.log(2*word.delay)+
                          (1-successFraction)*Math.log($defaultDelay))
    # the delay, plus some noise, determines the duedate
    word.duedate = Integer(0.5 + today + word.delay*Math.exp((rand-0.5)*$Noise))
  end
    



  public

  # call this to flag a card as... having appeared today
  def flagSeen(card)
    @seenToday.add(card.parent)
    card.parent.seen = true
  end

  # is an answer legitimate? Regardless of whether it's the one we
  # currently want...
  def legitimateAnswer(question,answer)
    return @qabank[question] && @qabank[question].include?(answer)
  end


  # Calculate the new stats on the cards, and save all the data.
  def closeEverything
    wrapUpCalculations
    data = pack
    File.open(@filename,'w') do |file|
      file.write(Psych.dump(data))
    end
  end
  
end




