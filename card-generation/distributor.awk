#!/bin/awk -f
BEGIN {
FS = ",";
OFS=",";
}
{
for(i = 2; i <= NF; i++) {
print $1,$i;
}
}
