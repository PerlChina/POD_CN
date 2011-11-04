#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

usage() unless @ARGV;
my $word = lc shift;

while (<DATA>) {
  if(lc((split /\t/, $_, 2)[0]) eq $word) {
    binmode STDOUT, ':utf8';
    print;
    last;
  }
}

exit;

sub usage {
  print "$0 word\n";
}

__DATA__
array	数组
hash	哈希
