#!/usr/bin/perl

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use version; our $VERSION = qw (1.0);

my $workdir;

# сменим рабочий каталог
BEGIN {
	use Cwd qw (chdir abs_path);
	my @CWD = split /\//xms, abs_path ($PROGRAM_NAME);
	if ($#CWD > 1) { $#CWD = $#CWD - 2; }
	$workdir = join '/', @CWD;
	chdir $workdir;
}

use lib ("$workdir/lib", "$workdir/vendor_perl", "$workdir/vendor_perl/lib/perl5");
use CHI;
use CHI::Driver::BerkeleyDB;
use Data::Dumper;
use YadProxy::Conf qw (LoadConf);

my $c = LoadConf ();
my $index_dir = $c->{index_dir};


my $index_dirs = CHI->new (
	driver => 'BerkeleyDB',
	root_dir => $index_dir,
	namespace => 'dirs'
);

say join "\n", $index_dirs->get_keys ();

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
