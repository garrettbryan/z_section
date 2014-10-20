#!/usr/bin/perl -w

#########################################################
####      extract Z section - Written by:           #### 
####                 Garrett Bryan                   ####
####                 Aug 12, 2012                    ####
#########################################################

print "
#############################################################
  You are using \"Extract Z Section\". Simply use your gcode 
file as the single argument. (see example below)
Usage: change_z_height.pl <directory to frames>
Example: change_z_height.pl /path/to/interested/file

  extract_z_section.pl allows you to pull a section of gcode 
that corresponds to a certain Z axis interval. All Z 
dimensions will be reformated so that the section will print 
on the printbed. This will allow anyone to pickup a failed 
print at a specific layer so that the object can be 
super-glued together.
#############################################################
";

if (!($#ARGV == 0) && ($ARGV[0] =~ m/gcode/) && (-f $original_gcode_file)){
exit 
}

&setvariables;
&gcodeanalysis;
&gcodesynthesis;

#print "$lower_distance\n";
#print "$upper_distance\n";

sub gcodesynthesis(){
	my $line;
	open NEW_GCODE_FILE, ">", "$original_gcode_file.new";
	open NEW_GCODE_LOG, ">", "$original_gcode_file.log";
	for($i = 0; $i < $header; $i++){
		print NEW_GCODE_FILE "$original_gcode_lines[$i]";
	}
	for($i = $body_start, $line = $i+1; $i <= $body_end; $i++, $line++){
		if ($original_gcode_lines[$i] =~ m/(G1 Z)([0-9]+\.[0-9]+)( .+)/){
			print NEW_GCODE_LOG "found $line $1$2 $3\n";
			my $newvalue = $2 - $lower_distance;
			$newvalue = sprintf("%.3f",$newvalue);
			print NEW_GCODE_FILE "G1 Z$newvalue $3\n";
			print NEW_GCODE_LOG "G1 Z$newvalue $3\n";

		}else{
			print NEW_GCODE_FILE "$original_gcode_lines[$i]";
		}
	}
	for($i = $#original_gcode_lines-$tail+1 ; $i <= $#original_gcode_lines; $i++){
		print NEW_GCODE_FILE "$original_gcode_lines[$i]";
	}
	close NEW_GCODE_FILE;
	close NEW_GCODE_LOG;
	print "$original_gcode_file.new\n$original_gcode_file.log\n";
}


sub gcodeanalysis(){
	open ORIGINAL_GCODE_FILE, "<", "$original_gcode_file";
	@original_gcode_lines = <ORIGINAL_GCODE_FILE>;
	close ORIGINAL_GCODE_FILE;
	my $line = 0;
	while ($verify_header eq "n"){
		for($i = 0; $i < $header; $i++){
			$line = $i + 1;
			print "$line: $original_gcode_lines[$i]";
		}
		if ($header != $oldheader){
			$header = &verify("How many lines of the header would you like to keep?
Generally I pull all of the skirt data in the header file.
(please enter a non-negative integer)\n",'^[0-9]+$');
			$oldheader = $header;
		}else{
			$verify_header = &verify("Is this correct? (enter y or n)\n",'^[yn]$');
			$oldheader = -1;
		}
	}
	$line = 0;
	while ($verify_tail eq "n"){
		for($i = $tail; $i > 0; $i--){
		$line = $i;
			print "$line: $original_gcode_lines[$#original_gcode_lines-$i+1]";
		}
		if ($tail != $oldtail){
			$tail = &verify("How many lines of the tail would you like to keep?
(please enter a non-negative integer)\n",'^[0-9]+$');
			$oldtail = $tail;
		}else{
			$verify_tail = &verify("Is this correct? (enter y or n)\n",'^[yn]$');
			$oldtail = -1;
		}
	}
	$line = 0;
	for($i = $header; $verify_body_start eq "n"; $i++){
		if (($original_gcode_lines[$i] =~ m/G1 Z([0-9.]+) (.*)/) && ($1 > $lower_distance)){
			$verify_body_start = "y";
			$body_start = $i;
			#print "first Z at $body_start\n";
		}
	}
	$line = 0;
	for($i = $body_start; $verify_body_end eq "n"; $i++){
		if ($i < $#original_gcode_lines){
			if (($original_gcode_lines[$i] =~ m/G1 Z([0-9.]+) (.*)/) && ($1 >= $upper_distance)){
				$verify_body_end = "y";
				$body_end = $i;
				#print "end Z at $body_end\n";
			}
		}else{
			$verify_body_end = "y";
			$body_end = $#original_gcode_lines-$tail;
			#print "end Z at $body_end\n";
		}
	}
}

sub setvariables(){
	$original_gcode_file = $ARGV[0];
	$header = 20;
	$oldheader = 0;
	$body_start = 0;
	$body_end = 0;
	$tail = 20;
	$oldtail = 0;
	$verify_header = "n";
	$verify_tail = "n";
	$verify_body_start = "n";
	$verify_body_end = "n";
	$lower_distance = 0;
	$upper_distance = 0;
	
	$lower_distance = &verify("Where should the extracted section start?
(the format is 0.0, 1.0, 3.25)\n",'^[0-9]+\.[0-9]+$');
	while ($upper_distance<$lower_distance){
		$upper_distance = &verify("Where should the extracted section end? 
If you want the remainder of the object enter
a value greater than the height of the object.end > start! 
(the format is 10.0, 11.0, 0.0)\n",'^[0-9]+\.[0-9]+$');
	}

}


sub verify(){ #first variable is question, 2nd variable is regex.
	my $verification = "n";
	my $answer;
	while($verification eq "n"){
		print "$_[0]";
		$answer = <STDIN>;
		chomp($answer);
		if ($answer =~ m/$_[1]/){
			$verification = "y";
		}else{
			print "Follow the format!\n";
		}
	}
	return $answer;
}