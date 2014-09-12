#!/usr/bin/perl
@ARGV_store=@ARGV;
use Cwd;
use File::Basename;
my $cwd;
if ($0 =~ m{^/})
{
  $cwd = dirname($0);
} else
{
  $cwd = dirname(getcwd()."/$0");
}
$R_RDXPloprer_package=$cwd;


require "$R_RDXPloprer_package/Binning.pl";
require "$R_RDXPloprer_package/interface.pl";
require "$R_RDXPloprer_package/collect_paired_info.pl";
require "$R_RDXPloprer_package/paired_MQ.pl";

$temp_remove=0;
print "$R_RDXPloprer_package\n";



#$temp_remove=1;
&interface;


if ((($PROC==1) or ($PROC==-1)) and ($INOUT_valid==1))
{
	print "$input	$output\n";
	print "	obtaining information from Bam file...\n";
	system "samtools view -X -F 0x400 $input | cut -f 1-9 > $output.pos";
	print "	Binning...\n";
	&binning("$output.pos");
	print "	RDXplorering...\n";
	system "Rscript RBatch.R $R_RDXPloprer_package $output";
	print "	Paired end info collecting...\n";
}


if ((($PROC==2) or ($PROC==-1)) and ($INOUT_valid==1))
{
	print "Retrieve paired-end information\n";
	&MQ_test("$output.pos");
	&collecting_paired_end_info("$output.pos");
	&paired_mapping_quality("$output.pos");

	for ($i=1;$i<=24;$i++)
	{
		undef %hash;
		#$i=1;
		$chr=$i;
		if ($i==23){$chr='X'}
		if ($i==24){$chr='Y'}
		$pr_file="$output.chr$chr.pr_dup";
		$id_file="$output.chr$chr.id_dup";
		&formating_dup("$id_file","$pr_file","$pr_file");
		$pr_file="$output.chr$chr.pr_del_0";
		$id_file="$output.chr$chr.id_del";
		$pr_file_new="$output.chr$chr.pr_del"; 
		&formating_del("$id_file","$pr_file","$pr_file_new");		
	}	
	
}


if ((($PROC==3) or ($PROC==-1)) and ($INOUT_valid==1))
{





		print "	===calculating support and p-value\n";
		open(input, "$output.MQ_report");
		while(<input>){if (/score/){@f=split /\:/, $_};$MAX_MQ=$f[1]};if ($MAX_MQ==0){print "ERROR: distribution is missing!!!!\n";}
		$Quality_cutof=0.8*$MAX_MQ;
		print "Quality cutoff is $Quality_cutof\n";
		if ($MQValid>0){$Quality_cutof=$MQValid;}
		
	for ($i=1;$i<=24;$i++)		#############################
	{
		undef %hash;
		#$i=1;
		$chr=$i;
		if ($i==23){$chr='X'}
    if ($i==24){$chr='Y'}
    $pr_file="$output.chr$chr.pr_del";
    $id_file="$output.chr$chr.id_del";
    $ref_file="$output.background_distribution.csv";
    $chr_id="chr$chr";
    $result_file="$output.chr$chr.del";    
    print "		====processing $chr_id. Result is in $result_file.txt\n";

		system "Rscript del_support.R $pr_file $id_file $ref_file $chr_id $result_file $Quality_cutof";
	}

	for ($i=1;$i<=24;$i++)
	{
		#$i=1;
		undef %hash;
		#$i=1;
		$chr=$i;
		if ($i==23){$chr='X'}
    if ($i==24){$chr='Y'}
    $pr_file="$output.chr$chr.pr_dup.new";
    $id_file="$output.chr$chr.id_dup";
    $ref_file="$output.background_distribution.csv";
    $chr_id="chr$chr";
    $result_file="$output.chr$chr.dup";    
    print "		====processing $chr_id. Result is in $result_file.txt\n";

		system "Rscript dup_support.R $pr_file $id_file $ref_file $chr_id $result_file $Quality_cutof";
	}



#	
	if ($temp_remove==1)
	{
		
	    $file="$output.pos";			
			system "rm $file";	
			system "rm $output*.distri";
			system "rm $output*_0";		
			system "rm $output.*.pr_dup";
	}
}