#!/bin/awk -f
BEGIN {
#lines=0;
    FS="_";
    OFS="";
    print "---";
    print "words:";
#oops
}
END {
    print "confusion: []";
}
{
#lines++;
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
