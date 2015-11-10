#!/bin/awk -f
#
# This script distributes a single Georgian verb across
# several English verbs, turning
#    და=ჭ(ე)რ-ის,wound,cut
# into
#    და=ჭ(ე)რ-ის,wound
#    და=ჭ(ე)რ-ის,cut

BEGIN {
    # make comma the field separator
    FS = ",";
    OFS=",";
}
{
    for(i = 2; i <= NF; i++) {
	print $1,$i;
    }
}
