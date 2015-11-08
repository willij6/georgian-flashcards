# georgian-flashcards
A console tool to help me learn Georgian.

There are two components

1. A flashcard manager, written in ruby
2. Scripts which produce the card database

## The flashcard manager
Running ```flashcards.rb``` starts the flashcard manager.
A sample interaction looks like

    ყურება?
    >> to watch
    That's right!
    წაღება?
    >> to take away
    That's right!
    მიძღვნა?
    >> to dedicate
    That's right!
    დაარსება?
    >> to establish
    That's right!
    შეტევა?
    >> to attack
    That's right!
    does dedicate?
    >> იძღვენს
    Sorry, wrong answer
    Right answer was უძღვნის
    does establish?
    >> აარსებობს
    Sorry, wrong answer
    Right answer was აარსებს
    does take away?
    >> იღებს
    That's right!
    does watch?
    >> უყურებს
    That's right!
    does attack?
    >> quit
    ნახვამდის!

The program expects some data on cards to be stored in a file called
```data.yml```.  For an example format of this file, see
```backup_data.yml```.

### The algorithm

The flashcard manager uses a simplistic version of [spaced
repetition](https://en.wikipedia.org/wiki/Spaced_repetition).
The basic algorithm has been tweaked in a few ways:

* The user doesn't rate how well she knows the answer.
  She either answers correctly or incorrectly.
* The user can flag certain words as easily confusable.
  The corresponding cards will be kept apart.
* Cards arising from the same word (e.g., დათვი -> bear and
  bear -> დათვი) are automatically kept apart.
* Cards requiring the same input method are bunched, to
  prevent excessive IME-switching.
* Spaced repetition is run independently on two separate levels:
  * Small scale: within an individual session
  * Large scale: over the course of weeks, months

My program has a slightly different goal than standard spaced
repetition sotware like [Mnemosyne](http://mnemosyne-proj.org) or
[Anki](http://ankisrs.net).  I wanted

1. A tool I could use in my free time, for as little or as much time as
   I wanted.
2. Something that would __not__ become another chore.
3. Something that could theoretically be used for cramming.

Consequently:

* There is no count of the cards remaining for the day.
* Successfully answering a card does not prevent it from reappearing
  in the same session.
* Within a session, cards are introduced at a slow pace, rather than
  all at once.


## Card generation
The ```card-generation``` folder contains sed, awk, and bash scripts
which generate the data.yml file.
Currently, the scripts can only handle Georgian verbs.

The file ```verbs.txt``` contains a list of lines that look like

    და=ა-ბრუნ-ებს
    return
    ბრძან-ებს
    command
    გა=ი-გ-ებს
    understand
    გადა=ა-გდ-ებს
    discard
    გა=გზავნ-ის
    send
    და=გრ-ეხს
    twist
    გა=ა-გრილ-ებს
    cool
    
Running the script all.sh expands all this data into properly formatted
YAML which can be fed into ```flashcards.rb```.

Each verb needs to generate five cards:

    cards:
      ka->en: !ruby/object:Card
        question: "დაბეჭდვა"
        answer: to print
      imperative: !ruby/object:Card
        question: print!
        answer: "დაბეჭდე"
      3aor: !ruby/object:Card
        question: did print
        answer: "დაბეჭდა"
      3pres: !ruby/object:Card
        question: does print
        answer: "ბეჭდავს"
      masdar: !ruby/object:Card
        question: to print
        answer: "დაბეჭდვა"


Things are complicated by the chaotic nature of Georgian verb conjugation.
(Half of B. G. Hewitt's reference grammar is devoted to the Georgian verb.)
