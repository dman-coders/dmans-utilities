#!/usr/bin/perl
# goes through a file and adds #anchors to each heading, with [#] tags.

sub rewrite_headings {
  my ($tag, $atts, $content) = @_;
  my $anchor = $content; 
  $anchor =~ s/[^a-z0-1]+/_/gi;
  return "<$tag$atts id=\"$anchor\">$content <a href=\"#$anchor\">#</a></$tag>";
}

# Just pour the data in from stdin. Pipe it yourself
while(<>) {
  $_ =~ s/<(H\d)(.*?)>(.*?)<\/\1>/
  rewrite_headings($1,$2,$3)
  /gise; 
  print $_;
}
