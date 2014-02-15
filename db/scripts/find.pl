use strict;
open F, 'test';


my $counter=0;

while(<F>){
chomp;	

#$_ =~ s/\\\|/<delimiter>/g;

print $_."\n";
#my $pattern =  "\";
my $pattern = "\\\|";
my $count = () = $_ =~ m/\\\|/g;

print "\tCount of $pattern : $count"; print "\n";


$counter++;
if($counter > 5){
	exit;
}

}
