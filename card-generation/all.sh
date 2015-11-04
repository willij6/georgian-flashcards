#!/bin/sh
# for now, get rid of third side info
sed 's/ (.*)//g' <temp_1_verbs.txt >t0.txt
# get rid of spaces after commas
sed 's/, /,/g' <t0.txt >te.txt
sed '
N
s/\n/,/' <te.txt >t.txt
awk -f distributor.awk <t.txt >tz.txt
sed -nf ka_verbs.sed <tz.txt >t2.txt
sed '
N
N
N
N
s/\n/_/g' <t2.txt >t3.txt
awk -f ka_verbs.awk <t3.txt >out.xml
rm t.txt t2.txt t3.txt t0.txt te.txt tz.txt