use strict;

open F, 'slash';

my $line = <F>;


my $count = $line =~ tr/\|//;


print $count
