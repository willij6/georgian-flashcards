#!/bin/sed -nf
#
# This script conjugates Georgian verbs,
# taking a compact description
#     გა=ა-კეთ-ებს
# a la Aronson's grammar, and converting it to
# a list of four of the conjugated forms

# More precisely, it turns
#     გა=ა-კეთ-ებს,make
# into
#     make
#     აკეთებს
#     გაკეთება
#     გააკეთე
#     გააკეთა
# These are the
# * English translation
# * third person singular present
# * masdar (analogue of the infinitive or gerund)
# * second person singular aorist, which is also the imperative
# * third person singular aorist

# Currently, only class 1/active/transitive verbs are handled,
# though a number of irregularities are correctly handled

# Verbs are presented in the format
#     PV=V-stem-PSFს
# where
# PV is the preverb (და, გადა, მო, მი, etc.)
# V is the preradical vowel
# PSF is the present-future stem formant (ებ, ავ, ამ, nothing, ი, or whatever)
#
# Each of these could conceivably be empty.
# An empty PV is indicated by a lack of an equals sign =.
# An empty V is indicated by a lack of a hyphen before the stem.
# An empty PSF is indicated by an empty PSF
#
# For instance:
# Word			PV	V	Stem	PSF
# და=წერ-ს		და	0	წერ	0
# გა=ა-კეთ-ებს		გა	ა	კეთ	ებ
# ბრძან-ებს		0	0	ბრძან	ებ
# გადა=თარგმნ-ის	გადა	0	თარგმნ	ი
# უ-ყურ-ებს		0	უ	ყურ	ებ
# ა-ქ-ებს		0	ა	ქ	ებს
#
# Following Aronson's notation,
# Sometimes the = is replaced with a +, to indicate that the Preverb
# appears in all the conjugated forms of the verb (even the present)
#
# Unlike Aronson, but following Hewitt, I'm considering
# -ევ- and -ენ- to be PSFs.  These stick around in the aorist,
# but undergo mutations ევ -> ი, ენ -> ი
# For simplicity, I handle all stems which change ე->ი this way,
# so I describe და=ი-ჭერ-ს as და=ი-ჭ-ერს.
# The rule is that any unknown PSF gets retained in the aorist,
# with ე changed to ი


# To flag irregularities in conjugation, certain things are
# put in parentheses within the stem
#
# (ვ) indicates a phantom ვ (v) which disappears before ო (o)
# So, to bake is გამო=ა-ცხ(ვ)-ობს; the v only appears in the imperative
#
# (ა) and (ე) denotes a vowel that (sometimes) appears in the aorist:
# * (ა) in a verb with PSF -ი indicates a _weak_ aorist
#   The vowel ა appears throughout the aorist screeve
# * (ე) in a verb with PSF -ი indicates a _strong_ aorist
#   The vowel ე appears in the 1st and 2nd person aorists
# * (ა) in a verb with PSF -ა indicates a _strong_ aorist
#   The vowel ა appears in the 1st and 2nd person aorists
#
# And while we're at it:
# * Any verb with PSF -ამ and no vowels in the stem is
#   assumed to take strong aorist endings


# Also, there are some variants in how the input may be formatted.
# Preverbs can be written like (და)- rather than და=,
# and [ and ] can be used rather than ( and )
#
# (I have a spreadsheet of Georgian verbs stored in this alternate format)

# TODO: do everything with ruby rather than sed

# Let's begin...


# 1. convert to Aronson-style formatting
#     (და)- converts to და=
s_^(\([^)]*\))-_\1=_
#     square braces convert to parentheses
s_\[_(_g
s_\]_)_g


# 2. handle the English word
# make the Georgian and English be separated by an underscore
#     და=ა-არს-ებს,establish -> და=ა-არს-ებს_establish
s/,/_/
# Note: only change the first comma, in case the English has commas
h                      # store "და=ა-არს-ებს_establish" in the hold buffer
s-^\(.*\)_\(.*\)$-\2-p # output "establish"
g                      # load "და=ა-არს-ებს_establish" back into pattern buf
s-^\(.*\)_\(.*\)$-\1-  # throw away "establish"

# now pattern space has და=ა-არს-ებს in it

# 3. ensure the preverb is there,
#    e.g.  ბრძან-ებს -> =ბრძან-ებს
/+/ ! {
  /=/ ! {
     # there's no preverb, so add "=" to the front
     s/^/=/
  }
}

# 4. ensure that the preradical vowel is there
#    e.g. და=წერ-ს -> და=-წერ-ს
s_^\(.*[=+]\)\([^-]*-[^-]*\)$_\1-\2_
# that checks if there's only one - after the = or +,
# and if so, inserts an - after the = or +

# 5. strip off the final ს
s/ს$//

# 6. Deal with phantom v.
#    (ვ) denotes a v/ვ that goes away before o/ო
#    The strategy is to replace (ვ) with a Roman v.
#    At the end of everything, we'll process it.
s_(ვ)_v_
#    Later, to handle things, we'll "devee"
#    s/vო/ო/
#    s/v/ო/
#    (we don't need s/.../.../g since there's at most one (ვ) per verb)


# At this point, we branch depending on which
# conjugation we want.  We'll go through them one by one,
# but for now, we save a copy of the current state,
# in sed's holding buffer.
h

# branch 1: present 3sg

# remove preverb if it's optional (flagged with = not +)
s/^.*=/=/
# remove parenthetical content: ჩა=-თვ(ა)ლ-ი becomes ჩა=-თვლ-ი
s/(.*)//
# remove the funny symbols (-, =, +)
s/[-+=]//g
# tack on a final ს
s/$/ს/


#devee!
s/vო/ო/
s/v/ვ/

# print
p


# branches 2-4: masdar, 2sgAor, 3sgAor

# All of these forms will definitely include the preverb,
# so we make note of this in our saved copy.
g # get the saved copy
s/+/=/ # + vs = distinguished optional vs mandatory preverb.  Now irrelevant
h # save the copy

# hold buffer now has something like აღ=-ნიშნ-ავ
# or და=-წერ-

# Branch 2: the Masdar
# do the appropriate thing with the psf
s/ი$//
s/ავ$/ვ/
s/ამ$/მ/

# remove parenthetical content
s/(.*)//


# compile it all together
# (NOTE the preradical vowel is discarded)
s_^\(.*\)=.*-\(.*\)-\(.*\)$_\1\2\3ა_

# devee!
s/vო/ო/
s/v/ვ/
# Oh snap, we have to worry ABOUT METATHESIS AND V-LOSS
# 'sequences involving a stop or fricative followed by a nasal
#  or liquid followed by v will generally have the v shift its
#  position to before the nasal or liquid'
s/\([ბგდზთკპჟსტფქღყშჩცძწჭხჯჰ]\)\([მნრლ]\)ვ/\1ვ\2/
# 'v is generally lost when it occurs before or after a lablial consonant'
s/\([ბფპმვ]\)ვ/\1/
s/ვ\([ბფპმვ]\)/\1/
p # print the masdar



# branches 3 and 4: the 2sg and 3sg aorists

# Some preliminary work needs to be done on both
# Many verbs systematically change their stem throughout the aorist,
# e.g. და-ი-ჭერ-ს changes ჭერ to ჭირ
#      გა  -შლ-ის changes შლ  to შალ
#       ა-ი-რჩევ-ს changes რჩევ to რჩი

# We'll handle this now



g # get აღ=-ნიშნ-ავ or და=-წერ- from the hold buffer

# if the stem ALWAYS changes, like in ჩა=-თვ(ა)ლ-ი, make the change
# [this only happens if there's an (ა) and the psf is ი]
s_(ა)\(.*-ი\)$_ა\1_ # change (ა) to ა if the string ends with -ი.
# handle pretend "PSF"s like ევ, ეტ, ...
s/-ევ$/ი-/ 	 	# so ა=ი-რჩ-ევ -> ა=ი-რჩი-
# any PSF like ეC, except ებ, gets the ე changed to ი and added to stem
s_-ე\([^ბ]\)$_ი\1-_ 	# so და=ი-ჭ-ერ -> და=ი-ჭირ-

h # save what we have so far back in the hold buffer

# Branch 3: 2sg aorist (= imperative)

# The 2sg aorist suffix is ე for a weak aorist, and ი for a strong
# aorist, so we need to figure out which it is.
#
# Anything remaining in parentheses would indicate a strong aorist.
# And if the stem is vowelless and -ამ is the PSF, then it's strong.
# Otherwise it's weak.

# We'll use the hack that IF we convert something to its final form,
# by getting rid of hyphens, THEN subsequent patterns won't match

# if parentheses are present, convert to final form
/(/ {
    # keep whatever's in parentheses
    s_(\(.*\))_\1_
    # finalize
    s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ი_ # PSF gets discarded
}

# if vowelless and -ამ, convert to final form
/-[^აეიოუ]*-ამ$/ {
    s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ი_ # PSF gets discarded
}

# otherwise, it's weak aorist, so the ending is ე
s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ე_

#devee! and print
s/vო/ო/
s/v/ვ/
p


# Branch 4: 3sg aorist
# Anything that's still in parentheses should get trashed.
# The suffix is ო if it's -ებ/-ობ with no vowels in stem
#          else ა.

g           # get აღ=-ნიშნ-ავ or და=-წერ- from the hold buffer
s/(.*)//    # dicsard parenthetical content

# the ო suffix
s_^\(.*\)=\(.*\)-\([^აეიოუ]*\)-[ეო]ბ$_\1\2\3ო_
# if that failed, this'll work:
s_^\(.*\)=\(.*\)-\(.*\)-.*$_\1\2\3ა_

#devee! and print
s/vო/ო/
s/v/ვ/
p


# whew, finally done