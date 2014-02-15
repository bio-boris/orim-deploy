#Script generates file for markers
#
use strict;

my $dir = "/web/html_stan/browser/data/MARKERS/";
my @filenames = split ("\n",`ls $dir | grep '.marker\$'`);
open O, ">markers" or die $!;

foreach my $fp(@filenames){
	my $org_name = join("",$fp =~ /.+_{1}/g);
	chop $org_name;
	print $org_name."\n";
	
	open F, $dir . "$fp" or die $!;
	while(<F>){
		chomp;
		my ($name,$chr,$start,$stop) = split /\t/, $_;
		if($stop > $start){
			print O join "\t", ($org_name,$name,$chr,$start,"$stop\n");
			#dont print bad markers

		}
	}
}

print
"
CREATE TABLE markers(
	org VARCHAR(255),
	marker VARCHAR(255) ,
	chr VARCHAR(255),
	start INT,
	stop INT 
);

";

print "
LOAD DATA LOCAL INFILE '/web/html_stan/browser/data/sqldatabase/markers' INTO TABLE markers 
FIELDS TERMINATED BY '\t';
";
