#!/bin/sed -nf

# convert to Aronson-style formatting
# (და)- converts to და=
# square braces convert to parentheses
s_^(\([^)]*\))-_\1=_
s_\[_(_g
s_\]_)_g

# change the divider between the georgian word and English word to
# an unusual symbol
s/,/_/
# NOT globally, just changing the first one!

# handle the English word
h
s-^\(.*\)_\(.*\)$-\2-p
g
s-^\(.*\)_\(.*\)$-\1-

# now have just the Georgian part in pattern space

# make sure the preverb is there
/+/ ! {
  /=/ ! {
     # there's no preverb, so add "=" to the front
     s/^/=/
  }
}

# make sure the preradical vowel is there
# და=წერ-ს -> და=-წერ-ს
s_^\(.*[=+]\)\([^-]*-[^-]*\)$_\1-\2_

# strip off the final ს
s/ს$//

# deal with phantom (ვ)
s_(ვ)_v_

# okay, now things are formatted consistently
h

# step 1: present 3sg

# remove parentheses: ჩა=-თვ(ა)ლ-ი becomes ჩა=-თვლ-ი
s/(.*)//
# remove the hyphens
s/-//g
s/+//g
# tack on a final ს
s/$/ს/
# remove an optional preverb
s/^.*=//

#devee!
s/vო/ო/
s/v/ვ/

# print
p


# steps 2-4
g
# don't care about = vs + now
s/+/=/
h
# hold buffer now has something like აღ=-ნიშნ-ავ
# or და=-წერ-

# step 2: masdar
# do the appropriate thing with the psf
s/ი$//
s/ავ$/ვ/
s/ამ$/მ/

# strip off parenthetical content
s/(.*)//




# compile it all together
s_^\(.*\)=.*-\(.*\)-\(.*\)$_\1\2\3ა_

#devee! WORRY ABOUT METATHESIS and print
s/vო/ო/
s/v/ვ/
# metathesis and v-loss
# 'sequences involving a stop or fricative followed by a nasal
#  or liquid followed by v will generally have the v shift its
#  position to before the nasal or liquid'
s/\([ბგდზთკპჟსტფქღყშჩცძწჭხჯჰ]\)\([მნრლ]\)ვ/\1ვ\2/
# 'v is generally lost when it occurs before or after a lablial consonant'
s/\([ბფპმვ]\)ვ/\1/
s/ვ\([ბფპმვ]\)/\1/
p

# steps 3-4: aorist prep
# get აღ=-ნიშნ-ავ or და=-წერ- from the hold buffer
g

# if the stem ALWAYS changes, like in ჩა=-თვ(ა)ლ-ი, make the change
# (this only happens if there's an (ა) and the psf is ი)
s_(ა)\(.*-ი\)$_ა\1_
# handle "psf"s like ევ, ეტ, ...
s/-ევ$/ი-/
s_-ე\([^ბ]\)$_ი\1-_
# the second of those lines doesn't trigger if the first does, because
# the first line "covers its tracks," obliterating the -ევ that was present

h

# step 3: imperative (2sg aorist)
# the issue here is deciding whether there's a strong aorist
# if anything's in parentheses, it's strong
# also if it's vowelless and -ამ is the final suffix

# we'll use the hack that if we convert it to final form, (getting rid
# of hyphens), subsequent patterns won't match

# if parentheses, convert to final form
/(/ {
    # keep whatever's in parentheses
    s_(\(.*\))_\1_
    # finalize
    s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ი_
}

# if vowelless and -ამ, convert to final form
/-[^აეიოუ]*-ამ$/ {
    s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ი_
}

# otherwise, it's weak aorist, so the ending is ე
s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ე_

#devee! and print
s/vო/ო/
s/v/ვ/
p


# step 4: 3sg aorist
g

# trash anything in parentheses
s/(.*)//

# basically, the suffix is ა, unless it's -ებ/-ობ with no vowels in stem
s_^\(.*\)=\(.*\)-\([^აეიოუ]*\)-[ეო]ბ$_\1\2\3ო_
# if that failed, this'll work:
s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ა_

#devee! and print
s/vო/ო/
s/v/ვ/
p
