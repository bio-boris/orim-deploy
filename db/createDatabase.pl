#!/usr/bin/env perl
use Term::ANSIColor;
use strict;
use Time::HiRes;
use DBI;
main();


my %data_sources;
my %orgs;

sub main(){
#Check to see if each data exists;
	print color 'magenta';
	print "We have generated data from ../generateData.pl, as well as have prepopulated folders with SQL schemas.\n".
		"Time to verify downloaded directories are good, load info from the organisms_list and begin creating the tables of data \n";
	print color 'reset'; 

	checkDataSources();

	%orgs = loadOrganisms();


	my @table_filepaths = ('organisms','chr','markers','recent','annotations','blast','gene_locations');
	checkTables(@table_filepaths);
	createTableData();
#inserTables();
}




sub checkTables{
#Filepaths to SQL files	
	my @table_filepaths = @_;
	print "Checking for existence of SQL files to create tables\n";
	foreach my $sql_file(@table_filepaths){
		fileExists("./sql/$sql_file.sql");
	}
}



sub createTableData(){
	print color 'cyan';	
	print "\nAbout to create data files to be inserted into each table.".
		"Will use the ../data direcotry \n";
	print color 'reset';
	mkdir('tmp');
	
	#Generate .table for :
	#Chr.sql, blast.sql, gene_locations.sql, organisms.sql 
	# #createChrTableData();
	# createBlastTableData();
	createGeneLocationsTableData_and_custom_annotations();
	#createOrganismsTableData();
        
	#Create Annotations
#	createAnnotationsTableData();
}





sub createGeneLocationsTableData_and_custom_annotations{
	printSchema('gene_locations');
	printYellow('Also generating fsf_pfam tables!');
	printSchema('annotations');

	my $start_time = Time::HiRes::gettimeofday();

	my $gene_locations_table = "tmp/gene_locations.table";
	my $custom_annotations_table = "tmp/custom_annnotations.table";
	
	createFile($custom_annotations_table);
	createFile($gene_locations_table);	

	my @headers = qw(Gene_id Org_id Chr Start Stop);
	open F, ">>$gene_locations_table" or die $!;
	open C, ">>$custom_annotations_table" or die $!;


	foreach my $org (sort keys %orgs){
		my $org_time = Time::HiRes::gettimeofday();
		my $fp = "../data/blast/".$org."_protein.fa_vs_phytozome9.reciprocal_blast.table";
		print "Opening file $fp\n";
		open my $fh, $fp or die;
		my $header = <$fh>;
		chomp $header;
		$header =~ s/_protein\t/\t/g;
		my @header = split /\t/, $header;
		while( my $line = <$fh>)
		{
			chomp $line;
			my @line = split /\t/, $line;
			my $gid = $line[0];
			my ($chr,$start,$stop) = split /\|/, $line[1];
			my ($fsf,$pfam) =split /\|/, $line[2];
			#Might need to split at something else
			$fsf =~ s/,no Pfam assignment//g;
			#Might be faster to sort the data?? Probably not , shouldnt matter for sql	
			
			#Instead of loading the files, just print em!
			print F (join "\t", ($gid,$org,$chr,$start,$stop)),"\n";
			print C (join "\t", ($gid,$org,'fsf_custom',$fsf)       ),"\n";
			print C (join "\t", ($gid,$org,'pfam_custom',$pfam)     ),"\n";
		}

		printf ("%.2f seconds\n",Time::HiRes::gettimeofday() - $org_time);
	}
	my $end_time = Time::HiRes::gettimeofday();
	print color 'red';
	printf("%.2f seconds\n", $end_time - $start_time);
	print color 'reset';
	close F;

	print "\nPrinted to  $gene_locations_table \n";
	print "\nPrinted to  $custom_annotations_table \n";
}

#Creates a blank file with a input name
sub createFile{
	my $fp = shift;
	open F, ">$fp" or die $!;
	print F "";
	close F;
}




#Removes _protein
#Loads up tables and prints out a file to be inserted"
#modifies evalue to have 1e100 instead ofi e100"
sub createBlastTableData(){
	printSchema('blast');
	my $start_time = Time::HiRes::gettimeofday();
	my %hash;

#Clear out file and make sure it exists
	my $blast_table_fp = 'tmp/blast.table';
	createFile($blast_table_fp);

	open F, ">>$blast_table_fp" or die $!;
#	print F join "\t", qw(g_id o_id hit_o_id hit_id hit_eval hit_identity hit_hit hit_hit_eval hit_hit_identity);

	foreach my $org(sort keys %orgs){

		my $org_time = Time::HiRes::gettimeofday();
		my $fp = "../data/blast/".$org."_protein.fa_vs_phytozome9.reciprocal_blast.table";
		print "Opening file $fp\n";
		open my $fh, $fp or die;
		my $header = <$fh>;
		chomp $header;
		$header =~ s/_protein\t/\t/g;
		my @header = split /\t/, $header;
		while( my $line = <$fh>)
		{
			chomp $line; 
			my @line = split /\t/, $line;
			my $gid = $line[0];
			my $cid= $line[1];
			my $annot = $line[2];
			for(my $i = 3; $i < scalar @header; $i++){
				my $o_id = $header[$i]; #ID grabbed from header
					if( $header[$i] eq "\n" ){next}; #Skip last tab
						my ($hit_id,
								$hit_eval,
								$hit_identity,
								$hit_hit_id,
								$hit_hit_eval,
								$hit_hit_identity) = split '\\\\\|', $line[$i];
				$hit_eval =~ s/^e-/1e-/;
				$hit_hit_eval =~ s/^e-/1e-/;
#hit hit = Top Hit of $gid's top hit

				my $count = $line[$i] =~ tr/\|//;

				my @print_line;
				foreach my $var( $gid,$org,$o_id,$hit_id,$hit_eval,$hit_identity,"$hit_hit_id","$hit_hit_eval" ,"$hit_hit_identity"){
					if (length $var == 0 ){
						push @print_line, "N/A";
					}
					else{
						push @print_line , "$var";
					}
				}
				print F (join "\t", @print_line);
				print  F "\n";
			}	  

		}
		printf ("%.2f seconds\n",Time::HiRes::gettimeofday() - $org_time);
#	blastToTableHelper($blast_table_fp,$org,\%hash);
	}
	my $end_time = Time::HiRes::gettimeofday();
	print color 'red';
	printf("%.2f seconds\n", $end_time - $start_time);
	print color 'reset';
	close F;

}

sub createOrganismsTableData(){
	printSchema('organisms');
}



#Creates a table that stores the chr max lengths
sub createChrTableData(){
	printSchema('chr');
	my $start_time = Time::HiRes::gettimeofday();
	my %hash;
	foreach my $org(keys %orgs){
		my $fp = "../data/phytozome_annotations/gene.gff/".$org."_gene.gff3";
		print "Opening file $fp\n";
		open my $fh, $fp or die;
		my $header = <$fh>; chomp $header;
		while( my $line = <$fh>)
		{
			chomp $line;
			my @line = split /\t/, $line;	
			my $cid = $line[0];
			my $feature = $line[2];
			my $start = $line[3];	
			my $stop =$line[4];

			if(length $cid ==0){
				$cid = 'unknown';
				$start='unknown';
				$stop='unknown';
			}

			if($feature eq 'mRNA'){
				if($stop > $hash{$org}{$cid}{'stop'}){
					$hash{$org}{$cid}{'stop'} = $stop;
				}				
				if($start < $hash{$org}{$cid}{'start'} || not defined $hash{$org}{$cid}{'start'} ){
					$hash{$org}{$cid}{'start'} = $start;
				}
			}		
		}
	}


	open F, ">tmp/chr.table" or die $!;
#	print F "O_id\tCid\tStart\tStop\n";
	foreach my $org(sort keys %hash){
		foreach my $cid(sort keys(%{$hash{$org}})){
			print F join "\t", $org, $cid, $hash{$org}{$cid}{'start'},$hash{$org}{$cid}{'stop'}, "\n";
		}
	}

	my $end_time = Time::HiRes::gettimeofday();
	print color 'red';
	printf("%.2f seconds\n", $end_time - $start_time);
	print color 'reset';


}




sub createOrganismsTableData(){
	printSchema('organisms');
	print color 'magenta';
	print "This table data is handmade, as it controls which organisms we want to look at. Look in data/organisms for it!";
	print color 'reset';
	print "\n\n";

}


sub printSchema(){
	my $fp = shift;
	open F, "./sql/$fp.sql" or die $!." '$fp' ";
	printYellow('-----------------------------------');
	printYellow("About to create data for $fp.sql");
	print <F>; close F;
	printYellow('-----------------------------------');

}








#Return a list of organisms
sub loadOrganisms{
	open F, '../data/organisms/organisms_list';
	my %organisms;
	my $count = 0;
	while(my $line=<F>){
		chomp $line;
		my ($id,$type,$latin,$name) = split /\t/, $line;
		$organisms{$id}{'latin'} = $latin;
		$organisms{$id}{'name'}= $name;
		$organisms{$id}{'id'} = $count;
		$organisms{$id}{'type'} = $type;
		$count++;
	}
	printYellow( "Discovered " . (scalar keys %organisms) . " Organisms from phytozome in the organsims_list file and kept the list!");
	return %organisms;

}


sub checkDataSources(){
	my @data_directories;
	open F, 'file_locations' or dieError("couldn't find configuration file");
	printYellow("Looking for directories from the file  'file_locations'");
	chomp(my @data_directories = <F>);
	if(fileExists('../data/organisms/organisms_list')){
		foreach my $dir(@data_directories){
#print "Checking if '$dir' exists\n";
			dirExists($dir);
		}
	}
	close F;

}


sub printYellow(){
	print color 'yellow';
	print shift,"\n";
	print color 'reset';
}



#Collection of functions that check if something exists or not
sub dirExists(){
	my $dir = shift;
	if(-d $dir){
		announceExists($dir);
		return 1;
	}
	else{
		dieError("Directory $dir does not exist!");
	}

}
sub fileExists(){
	my $filename = shift;
	if(-e $filename){
		announceExists($filename);
		return 1;
	}	
	else{
		dieError("file $filename does not exist!");
	}
}
sub announceExists(){
	my $name = shift;
	print "$name ";
	print color 'green';
	print ' 'x(65 - length($name));

	print "Exists\n";
	print color 'reset';
}
sub dieErrorNormal(){
	die shift;
}

sub dieError(){
	my $message = shift;
	print color 'red';
	print $message . "\n\n";
	print color 'reset';
	die ;
}
#
sub continueError(){
	print color 'red';
	print (shift) . "\n\n";
	print color 'reset';
}
