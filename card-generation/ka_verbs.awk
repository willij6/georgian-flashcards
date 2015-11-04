#!/bin/awk -f
BEGIN {
#lines=0;
FS="_";
OFS="";
#oops
}
{
#lines++;
print "<lex category=\"Georgian Verbs\">";
print "<card subcategory=\"1\">";
print "<question>", $3, "</question>";
print "<answer>to ", $1, "</answer>";
print "</card>";

print "<card subcategory=\"2\">";
print "<question>", $1, "!</question>";
print "<answer>", $4, "</answer>";
print "</card>";

print "<card subcategory=\"3\">";
print "<question>did ", $1, "</question>";
print "<answer>", $5, "</answer>";
print "</card>";

print "<card subcategory=\"4\">";
print "<question>does ", $1, "</question>";
print "<answer>", $2, "</answer>";
print "</card>";

print "<card subcategory=\"5\">";
print "<question>to ", $1, "</question>";
print "<answer>", $3, "</answer>";
print "</card>";

print "</lex>";
}
