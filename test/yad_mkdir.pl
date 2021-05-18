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
use YadProxy::Conf qw (LoadConf);
use YadProxy::Lib qw (GetAccessToken);
use Yandex::Disk;
use Data::Dumper;

my $c = LoadConf ();
my $remote_dir = '/';

if ($c->{remote_dir} && $c->{remote_dir} ne '') {
	$remote_dir = $c->{remote_dir};

	$disk->createFolder (-path => $remote_dir, -recursive => 1) or do {
		die "Невозможно создать каталог $c->{remote_dir} на Yandex.Диске";
	};
}

my $disk = Yandex::Disk->new( -token => GetAccessToken );
$disk->createFolder(-path => 'myYaD/test', -recursive => 1);
say Dumper $disk->listFiles (-path => '/');

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
