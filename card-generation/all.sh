#!/bin/sh

# this script expands compact descriptions
# of Georgian verbs into flash cards which
# test all the principle parts of the verbs
#
# In other words, it turns THIS:
#     და=ჭ(ე)რ-ის
#     wound, cut (bread)
# into THIS:
#     - !ruby/object:Word
#       category: ka-verb
#       cards:
#         ka->en: !ruby/object:Card
#           question: "დაჭრა"
#           answer: to wound
#         imperative: !ruby/object:Card
#           question: wound!
#           answer: "დაჭერი"
#         3aor: !ruby/object:Card
#           question: did wound
#           answer: "დაჭრა"
#         3pres: !ruby/object:Card
#           question: does wound
#           answer: "ჭრის"
#         masdar: !ruby/object:Card
#           question: to wound
#           answer: "დაჭრა"
#     - !ruby/object:Word
#       category: ka-verb
#       cards:
#         ka->en: !ruby/object:Card
#           question: "დაჭრა"
#           answer: to cut
#         imperative: !ruby/object:Card
#           question: cut!
#           answer: "დაჭერი"
#         3aor: !ruby/object:Card
#           question: did cut
#           answer: "დაჭრა"
#         3pres: !ruby/object:Card
#           question: does cut
#           answer: "ჭრის"
#         masdar: !ruby/object:Card
#           question: to cut
#           answer: "დაჭრა"
#     - !ruby/object:Word
#       category: ka-verb
#       cards:
#         ka->en: !ruby/object:Card
#           question: "გაჭრა"
#           answer: to cut
#         imperative: !ruby/object:Card
#           question: cut!
#           answer: "გაჭერი"
#         3aor: !ruby/object:Card
#           question: did cut
#           answer: "გაჭრა"
#         3pres: !ruby/object:Card
#           question: does cut
#           answer: "ჭრის"
#         masdar: !ruby/object:Card
#           question: to cut
#           answer: "გაჭრა"

# Each verb is described by two lines in the input file verbs.txt
# * The first has a compact description of the verb,
# * The second has a comma separated list of English translations
#   of the word.  Each translation might be several words,
#   and there might be a parenthetical note.
# Currently the parenthetical note is ignored, but ideally,
# it could become a "third side" of the resulting cards.

# all.sh (this file) makes use of a few helper scripts:
#
# 1. The current strategy for handling words that have multiple
#    English translations is to just duplicate the original verb.
#    So
#        შე=ღებ-ავს,paint,color
#    Turns into
#        შე=ღებ-ავს,paint
#        შე=ღებ-ავს,color
#    The script distributor.awk handles this.
#
# 2. The script ka_verbs.sed handles the grammar of Georgian verbs
#    converting a compact description like გა=ი-გ-ებს into the list of
#    conjugated forms
#
# 3. The script to_yml.awk assembles the processed English and Georgian
#    forms into a YAML description of the required cards.
#    (There's an analogous script to_xml.awk which I used in an earlier
#     version of this program)



# The script is organized as a massive pipeline.
# For debugging purposes, the intermediate results are stored
# in files (rather than literally piping all the commands together).
# The temporary files are cleared up at the end

# The comments below will demonstrate what each step does to
# the following example:
#     და=ჭ(ე)რ-ის
#     wound, cut (bread)



# და=ჭ(ე)რ-ის
# wound, cut (bread)
sed 's/ (.*)//g' <verbs.txt >t0.txt # remove parentheses
# და=ჭ(ე)რ-ის
# wound, cut
sed 's/, /,/g' <t0.txt >te.txt # remove spaces after commas
# და=ჭ(ე)რ-ის
# wound,cut
sed '
N
s/\n/,/' <te.txt >t.txt # group pairs of lines into single lines
# და=ჭ(ე)რ-ის,wound,cut
awk -f distributor.awk <t.txt >tz.txt
# და=ჭ(ე)რ-ის,wound
# და=ჭ(ე)რ-ის,cut

# # now let's forget about cut

# და=ჭ(ე)რ-ის,wound
sed -nf ka_verbs.sed <tz.txt >t2.txt # conjugate the verbs
# wound
# ჭრის
# დაჭრა
# დაჭერი
# დაჭრა
sed '
N
N
N
N
s/\n/_/g' <t2.txt >t3.txt # group the lines by 5, separating by an underscore
# wound_ჭრის_დაჭრა_დაჭერი_დაჭრა
awk -f to_yml.awk <t3.txt >out.yml # convert to YAML.  To get xml, use to_xml.awk
# - !ruby/object:Word
#   category: ka-verb
#   cards:
#     ka->en: !ruby/object:Card
#       question: "დაჭრა"
#       answer: to wound
#     imperative: !ruby/object:Card
#       question: wound!
#       answer: "დაჭერი"
#     3aor: !ruby/object:Card
#       question: did wound
#       answer: "დაჭრა"
#     3pres: !ruby/object:Card
#       question: does wound
#       answer: "ჭრის"
#     masdar: !ruby/object:Card
#       question: to wound
#       answer: "დაჭრა"

# # Finally, clean everything up
rm t.txt t2.txt t3.txt t0.txt te.txt tz.txt

