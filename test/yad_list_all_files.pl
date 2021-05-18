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
use YadProxy::Lib qw (GetAccessToken);
use Yandex::Disk;
use Data::Dumper;

my $disk = Yandex::Disk->new ( -token => GetAccessToken );
say Dumper $disk->listAllFiles ();

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4: