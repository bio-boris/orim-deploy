#********WARNING THIS SCRIPT WILL DELETE EXISTING TABLE AROUND LINE 83!!!!
#
#*************************************************************************#
#This script creates a database for the iplant QTL browser
#*************************************************************************#
#To be run in browser/data/sql_schemagenerator 

#Table: dicot_blast
#Table: monocot_blast
#This scripts gets all the databases by looking in the SeedCi directory and gets the names of the files there
#Then it creates 2 tables, one for dicots and one for monocots
#Then it creates a temporary tab delimited file for insertion

#Table: phytozome_annot
#&create_phytozome_annotations_schema();
#&populate_phytozome_annotations();

#Table: annotations
#our FSF/PFAM annotations, and custom annotations from tair, other databases TBD
#&create_custom_annotations_schema();
#&populate_custom_annotations();
#This table also updates 'aliases' for genes for athaliana


##############################################################################
# Files and directories used:
# data/sqldatabase/create_database.pl script
# ../seedCI/  or ../blast_tables	(.table files that contain blast hits and some FSF/PFAM annotation IDs)
# ../phytozomeAnnotations/  	(_annotations.txt files from phytozome)
# ../otherAnnotations	(fsf and pfam files generated by us)	
##############################################################################
#*************************************************************************#
use strict;
use Scalar::Util qw(looks_like_number);
use DBI;

#Get list of all organisms that have the .table files and their filepaths
my @list_of_organism_filenames = sort split /\n|\r/, `ls ../blast_tables/ | grep table\$ `; 
my @list_of_organisms = sort split /\n|\r/, `ls ../blast_tables | egrep -o ".+_[0-9]+" | uniq ` ;
my @monocots;
my @dicots;
my %table;
my %filepaths;
chomp(my $pwd =  `pwd`);
my $dbh = DBI->connect('DBI:mysql:iplant', 'iplant', 'seedci'
	           ) || die "Could not connect to database: $DBI::errstr";
main();	   
sub main
{
	#SQL DATABASE STUFF
	#PART ONE
	#*************************************************************************#
	#1) Create SQL for Two Tables
	#2) Create multiple tab delimited files from the table files
	#2) Then populate the table
	
	#generateBlastSchema();	
	#createINFILE_then_insert(@list_of_organisms);

	#PART TWO
	#*************************************************************************
	#Create Tab Delimited Table ANNOTATION FILES
	#phytozome
	
	#create_phytozome_annotations_schema();
	#populate_phytozome_annotations();
	
	#Part THREE
	#our FSF/PFAM annotations, and custom annotations from tair, other databases TBD

	&create_custom_annotations_schema();
	&populate_custom_annotations();
}			   


#################################################################################################################
#This function creates an  tab delim temp file containing the blast table for each org
sub createINFILE_then_insert
{
	#This function loads up both files and stitches them together
	#I could have done a paste side by side but I wanted to make sure 100% that the input data files would line up, just in case
	for(my $i = 0; $i< scalar @list_of_organism_filenames; $i+=2){
		my %hash;
		my $filepath = "../blast_tables/$list_of_organism_filenames[$i]"; #Dicot
		my $filepath2 = "../blast_tables/$list_of_organism_filenames[$i+1]"; #Monocot
		my @headers;
		my $current_organism;
		my $org_short;
		
		#Load up each file into a hash, #numberoforgs -1 + current_org +   chr_start_stop + fold_fam/pfam
		#$hash{header} = $value
		foreach my $fp( $filepath,$filepath2){
			open F, $fp or die $!;
			my $line_count = 0;
			while( my $line =<F>){
				chomp $line;
				if($line_count ==0 ){
					$line_count++;
					@headers = split /\t/, $line;
					$current_organism = $headers[0];
					$org_short = $filepaths{'full'}{$current_organism};
				}
				else{
					my ($id_pac,$location,$annotation,@orgs) = split /\t/, $line;
					my ($id,$pac) = split /\|/, $id_pac;
					my ($chr,$start,$stop) = split /\|/, $location;
					$hash{$id}{'pac'} = $pac;
					$hash{$id}{'chr'} = $chr;
					$hash{$id}{'start'} = $start;
					$hash{$id}{'stop'} = $stop;
					for(my $i =0; $i < scalar(@orgs) ; $i++){
						my $org_name = $headers[3+$i];
						my $hit = $orgs[$i];
						$hit =~ s/\|/\\|/g;	
						$hash{$id}{$org_name} = $hit;
					}
				}
			}
			close F;
		}
		#id,pacid,org,chr,start,stop,alphabeticalorglist
		open F , '>tmp' or die $!;
		foreach my $id(keys %hash){
			my $pac		= $hash{$id}{'pac'};
			my $chr 	= $hash{$id}{'chr'} ;
		    my $start 	= $hash{$id}{'start'} ;
			my $stop 	= $hash{$id}{'stop'} ;

			my @line_of_orgs;
			foreach my $org(sort @list_of_organisms){	
				if($current_organism eq $org."_peptide"){
					push @line_of_orgs, 'null';
				}
				else{
					push @line_of_orgs, $hash{$id}{"$org"."_peptide"};
				}
				#print $_,"_peptide\n";
				
			}
			
			print F join "\t", $id, $pac, $org_short, $chr,$start,$stop,@line_of_orgs;
			print F "\n";
		
		}
		close F;
		
		my $insert = "LOAD DATA INFILE '$pwd/tmp' INTO TABLE blast FIELDS TERMINATED BY '\t'";
		if($dbh->do($insert)){
			print "inserted rows succesfully\n";
		}
		else{
			print "problem with rows insert\n";
		}
		print "created infile for $org_short and inserted into blast\n";	
	}

}
sub generateBlastSchema{

	#create filepaths hash for later
	foreach my $fp(@list_of_organism_filenames){
		my ($org_name,$rest) = split /\.fa/ , $fp;
		my @name = $org_name =~ m/[\w]+_/g;
		my $name = $name[0];
		chop $name;
		$filepaths{'full'}{$org_name} = $name;
		$filepaths{'short'}{$name} = $org_name;
	}
	

	my $table = 
	"CREATE TABLE blast
	(
	id VARCHAR(255) NOT NULL PRIMARY KEY,
	pac_id VARCHAR(255),
	org VARCHAR(255) NOT NULL,
	chr VARCHAR(255) NOT NULL,
	start INT NOT NULL,
	stop INT NOT NULL,\n";

	foreach my $org(sort @list_of_organisms){
		$table .= "\t$org VARCHAR(255),\n";
	}
	chop $table; chop $table; #Remove , and \n
	$table .= "\n)\n";

	#Print to
	open F, ">./schemas/create_blast_table.sql" or die $!;
	print F $table;
	close F;
	
	#CREATE THE DATABASE IF IT DOESN"T EXIST; 
	$dbh->do('drop table blast');
	print "\ndropping table blast";
	$dbh->do($table);
	print "\ncreating table blast\n\n";
	
}	
#################################################################################################################


sub populate_custom_annotations
{
	#GRAB FSF_PFAM data from the blast table files and create hash of them
	my @filepaths;
	for(my $i = 0; $i< scalar @list_of_organism_filenames; $i+=2){
		push @filepaths, "../blast_tables/$list_of_organism_filenames[$i]";
	}
	my %annotations;
	foreach my $fp(@filepaths){
		my $org = (split /\//, $fp)[-1];
		$org =~ s/_peptide.+//g;
		open F, $fp or die $!;
		my $linecount = 0;
		while(my $line=<F>){
			next if ($linecount++ ==0);
			my @line = split /\t/, $line;
			my ($id,$pac) = split /\|/, $line[0];
			$annotations{$id}{'fsf_pfam'} = $line[2];
			$annotations{$id}{'org'} = $org;
		}
		close F;
	}
		print "Loaded fsf_pfam\n";

	#Load up our OTHER custom PFAM/FSF files 
	my @fsf_pfam = split /\n/,`ls ../fsf_pfam/`;
	foreach my $fp(@fsf_pfam){
		open F, "../fsf_pfam/".$fp or die $!;
		while(<F>){
			chomp;
			my ($temp,$rest) = split /\t/, $_, 2;
			my ($id,$pac) = split /\|/, $temp;
			$annotations{$id}{'fsf_pfam2'} = $rest;
		}
	}
	
		print "Loaded custom synonym\n";
	
	#Load up synonyms
	my @synonyms = split /\n/,`ls ../aliases/ | grep ".txt\$"`;
	foreach my $fp(@synonyms){
		open F, "../aliases/".$fp or die $!;
		while(<F>){
			chomp;
			my ($temp,$rest) = split /\t/, $_, 2;
			my ($id,$pac) = split /\|/, $temp;
			$annotations{$id}{'phyotozome_synonyms'} = $rest;
		}
	}
	
	print "Loaded phyotzome synonym \n";
	
	#Load up defline
	my @synonyms = split /\n/,`ls ../defline/ | grep ".txt\$"`;
	foreach my $fp(@synonyms){
		open F, "../defline/".$fp or die $!;
		while(<F>){
			chomp;
			my ($temp,$rest) = split /\t/, $_, 2;
			my ($id,$pac) = split /\|/, $temp;
			$annotations{$id}{'phyotozome_defline'} = $rest;
		}
	}
	print "Loaded phytozome defline\n";
	
	my %hashcount;
	open O, '>annotations_infile' or die $!;
	foreach my $id(sort keys %annotations){ 
		my $org = $annotations{$id}{'org'};
		my $fsf_pfam = $annotations{$id}{'fsf_pfam'};
		my $fsf_pfam2 = $annotations{$id}{'fsf_pfam2'};
		my $phytozome_alias =  $annotations{$id}{'phyotozome_synonyms'} ;
		my $phytozome_defline =  $annotations{$id}{'phyotozome_defline'} ;
		my $other_synonyms = 'null';
		

		$fsf_pfam2 =~ s/\t/<delimiter>/g;
		
		print O join "\t", $id, $org, $fsf_pfam, $phytozome_alias, $other_synonyms, $phytozome_defline;
		print O "\n";		
	}
		
	foreach(keys %hashcount){
		print $_, $hashcount{$_},"\n";
	
	}
		
	#Insert the tmp file into DB
	my $insert = "LOAD DATA INFILE '$pwd/annotations_infile' INTO TABLE annotations FIELDS TERMINATED BY " . '"\t"' ;
	if($dbh->do($insert)){
		print "inserted rows succesfully\n";
	}
	else{
		print "problem with rows insert phytozome_annotations";
	}
	
	
	#Load up TAIR's synonym names
	#These are generated in gene_aliases_to_db.pl
	open F, '../tair/Athaliana.alias';
	while(my $line=<F>)
	{
		chomp $line; #We need to chomp here because this is not an infile, but a bunch of updates
		my @line = split "\t", $line;
		my ($id,$alias) = ($line[0],$line[1]);
		my $update = "UPDATE annotations SET other_synonyms='$alias' WHERE id LIKE \"$id%\";";
		#print $update,"\n";
		$dbh->do($update);
		
	}
	
	#ftp://ftp.arabidopsis.org/home/tair/Genes/gene_aliases.20120207.txt
	#Load up GO terms?
	
	#So currently the problem is with the script that edits the gene aliases.
	#I need to make a new datastructure for it, and combine the symbols:synoyms
	
	#CLose, there is some sort of problem left with '< or something"
	print "\nupdating athaliana's geneID's with aliases/synonyms\n";
	close F;
	print "updated\n";
	
	
}



sub create_custom_annotations_schema
{
	my $custom_schema = 
"
CREATE TABLE annotations
(
	id VARCHAR(255) PRIMARY KEY,
	org VARCHAR(255) NOT NULL,
	fsf_pfam VARCHAR(255),
	synonyms VARCHAR(255),
	other_synonyms VARCHAR(255),
	defline VARCHAR(255)
)";
	$dbh->do('drop table annotations');
	print "\ndropping table annotations\n";
	$dbh->do($custom_schema);
	print "creating  table annotations\n";

}



sub populate_phytozome_annotations
{
	my @phytozome_filepaths = split /\n/, `ls ../phytozomeAnnotations/ | grep 'annotation_info.txt\$' `;
	print "\n";
	for(my $i =0 ;$i < scalar @phytozome_filepaths; $i++)
	{
		my $fp  = $phytozome_filepaths[$i];
		#Get org name
		my $org = $fp;
		$org =~ s/_annotation_info\.txt//;
		#Generate the tmp file!
		open F, "../phytozomeAnnotations/$fp" or die $!;
		open G, ">tmpAnnot" or die $!;
		while(my $line = <F>)
		{
			my @line = split /\t/, $line;
			my $temp_id = shift @line;
			print G join "\t", $temp_id,$org,@line; #id,org,annotations
		}		
		print "Generated phytozome annotations file for $org\n";
		close F;
		close G;
		#Insert the tmp file into DB
		my $insert = 'LOAD DATA INFILE \'' . "$pwd/tmpAnnot" .'\' INTO TABLE phytozome_annot FIELDS TERMINATED BY \'\t\'' ;
		if($dbh->do($insert)){
			print "inserted rows succesfully\n";
		}
		else{
			print "problem with rows insert for $org\n";
		}
	}
}

			   
			   
#this works for phytozome version 8
sub create_phytozome_annotations_schema
{
	my $phyotzome_annotations_schema = 
	"create table phytozome_annot
	(
		id VARCHAR(255) PRIMARY KEY,
		org VARCHAR(255) NOT NULL,
		pfam VARCHAR(255),
		panther   VARCHAR(255),
		kog 	  VARCHAR(255),
		kegg_ec VARCHAR(255),
		kegg_orth VARCHAR(255),
		araHit VARCHAR(255),
		araSymbol VARCHAR(255),
		araDefline VARCHAR(255),
		riceHit VARCHAR(255),
		riceSymbol VARCHAR(255),
		riceDefline VARCHAR(255)
	)";
	$dbh->do('drop table phytozome_annot');
	print "\ndropping table phytozome_annot\n";
	$dbh->do($phyotzome_annotations_schema);
	print "creating  table phytozome_annot\n";
}










#Cleanup!
#unlink('tmp');
#unlink('tmp2');
#unlink('tmpAnnot');
