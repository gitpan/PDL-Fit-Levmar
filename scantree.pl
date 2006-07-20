# Modified version of scantree to build  online pdl documentation from
# more than one tree. Eg, PDL is installed in the  'perl' location
# and locally built modules in the 'site' location
# The db is put into the first directory listed
# eg 
# perl ./scantree.pl  /usr/lib/perl5 /usr/local/lib/perl/5.8.8
# in general
# perl ./scantree.pl  instpath1 instpath2 ... [ fqpndb ]

# I don't claim this is at all robust, but it worked for me.

use PDL::Doc;
use Getopt::Std;
use Config;
use Cwd;

require PDL; # always needed to pick up PDL::VERSION

sub deb { print STDERR $_[0],"\n"}

$opt_v = 0;

getopts('v');
$outdb  = pop @ARGV if $ARGV[$#ARGV] =~ /db$/ ;
@dirs = @ARGV;

deb "got dirs " . join(":",@dirs) . " db '$outdb'.";

unless (defined $dirs[0]) {
	($dir = $INC{'PDL.pm'}) =~ s/PDL\.pm$//i;
	umask 0022;
	print "DIR = $dir[0]\n";
}

unless (defined $outdb) {
	$outdb = "$dirs[0]/PDL/pdldoc.db";
	print "DB  = $outdb\n";
}

$currdir = getcwd;

unlink $outdb if -e $outdb;
$onldc = new PDL::Doc();
$onldc->outfile($outdb);

foreach  $dir ( @dirs ) {
    deb "Processing '$dir' ... ";
    chdir $dir or die "can't change to $dir";
    $dir = getcwd;
    $onldc->scantree($dir."/PDL",$opt_v);
    $onldc->scan($dir."/PDL.pm",$opt_v) if  -e $dir."/PDL.pm" ;
}

chdir $currdir;

print STDERR "saving...\n";
$onldc->savedb();
@mods = $onldc->search('module:',['Ref'],1);
@mans = $onldc->search('manual:',['Ref'],1);
@scripts = $onldc->search('script:',['Ref'],1);
$outdir = "$dirs[0]/PDL";
# ($outdir = $INC{'PDL.pm'}) =~ s/\.pm$//i;
open POD, ">$outdir/Index.pod"
  or die "couldn't open $outdir/Index.pod";
print POD <<'EOPOD';

=head1 NAME

PDL::Index - an index of PDL documentation

=head1 DESCRIPTION

A meta document listing the documented PDL modules and
the PDL manual dcouments

=head1 PDL manuals

EOPOD

#print POD "=over ",$#mans+1,"\n\n";
print POD "=over 4\n\n";
for (@mans) {
  my $ref = $_->[1]->{Ref};
  $ref =~ s/Manual:/L<$_->[0]|$_->[0]> -/;
##  print POD "=item L<$_->[0]>\n\n$ref\n\n";
#  print POD "=item $_->[0]\n\n$ref\n\n";
  print POD "=item *\n\n$ref\n\n";
}

print POD << 'EOPOD';

=back

=head1 PDL scripts

EOPOD

#print POD "=over ",$#mods+1,"\n\n";
print POD "=over 4\n\n";
for (@scripts) {
  my $ref = $_->[1]->{Ref};
  $ref =~ s/Script:/L<$_->[0]|PDL::$_->[0]> -/;
##  print POD "=item L<$_->[0]>\n\n$ref\n\n";
#  print POD "=item $_->[0]\n\n$ref\n\n";
  print POD "=item *\n\n$ref\n\n";
}

print POD << 'EOPOD';

=back

=head1 PDL modules

EOPOD

#print POD "=over ",$#mods+1,"\n\n";
print POD "=over 4\n\n";
for (@mods) {
  my $ref = $_->[1]->{Ref};
  next unless $_->[0] =~ /^PDL/;
  if( $_->[0] eq 'PDL'){ # special case needed to find the main PDL.pm file.
	  $ref =~ s/Module:/L<PDL::PDL|PDL::PDL> -/;
##	  print POD "=item L<PDL::PDL>\n\n$ref\n\n";
#	  print POD "=item PDL::PDL\n\n$ref\n\n";
	  print POD "=item *\n\n$ref\n\n";
	  next;
  }
  $ref =~ s/Module:/L<$_->[0]|$_->[0]> -/;
##  print POD "=item L<$_->[0]>\n\n$ref\n\n";
#  print POD "=item $_->[0]\n\n$ref\n\n";
  print POD "=item *\n\n$ref\n\n";
}

print POD << "EOPOD";

=back

=head1 HISTORY

Automatically generated by scantree.pl for PDL version $PDL::VERSION.

EOPOD

close POD;

