#!/usr/bin/perl

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use version; our $VERSION = qw (1.0);

my $workdir;

# Надо сменить рабочий каталог до запуска основной логики
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
use YadProxy::Conf qw (LoadConf);

my $c = LoadConf ();

my $cache = CHI->new (
	driver => 'BerkeleyDB',
	root_dir => $c->{oauth_dir},
	namespace => 'yad_auth'
);

my $refresh_token = $cache->get ('refresh_token');
my $access_token = $cache->get ('access_token');

if (defined $refresh_token && defined $access_token) {
	printf "access_token:\n%s\n\nrefresh_token:\n%s\n", $access_token, $refresh_token;
} else {
	say "Что-то пошло не так, токены не нашлись, попробуйте их пере-получить через скрипт yad_get_token.pl";
	exit 1;
}

exit 0;

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
