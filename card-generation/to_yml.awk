#!/bin/awk -f

# this file expands a list
#     wound_ჭრის_დაჭრა_დაჭერი_დაჭრა
# into a full description of a set of flash cards,
# in my desired YAML format.  This looks like
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
# though this is subject to change.
#
# Underscores are used as input field separator,
# because the English translation might be several words,
# like "tear apart"

BEGIN {
    FS="_";
    OFS="";

    print "---";
    print "words:";
}
{
    # English_present3sg_infinitive_imperative_past3sg
    #  $1        $2          $3        $4       $5
    print "- !ruby/object:Word";
    print "  category: ka-verb";
    print "  cards:";
    print "    ka->en: !ruby/object:Card";
    print "      question: \"", $3, "\"";
    print "      answer: to ", $1;
    print "    imperative: !ruby/object:Card";
    print "      question: ", $1, "!";
    print "      answer: \"", $4, "\"";
    print "    3aor: !ruby/object:Card";
    print "      question: did ", $1;
    print "      answer: \"", $5, "\"";
    print "    3pres: !ruby/object:Card";
    print "      question: does ", $1;
    print "      answer: \"", $2, "\"";
    print "    masdar: !ruby/object:Card";
    print "      question: to ", $1;
    print "      answer: \"", $3, "\"";
}
END {
    # confusion is a list of word pairs that the user
    # has flagged as _easily mix-up'able_.
    # Initially, this list should start out empty.
    print "confusion: []";
}
