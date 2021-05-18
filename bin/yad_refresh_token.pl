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
use Yandex::OAuth;
use YadProxy::Conf qw (LoadConf);

my $c = LoadConf ();

my $oauth = Yandex::OAuth->new (
	client_id     => $c->{ID},
	client_secret => $c->{'Пароль'},
);

my $cache = CHI->new (
	driver => 'BerkeleyDB',
	root_dir => $c->{oauth_dir},
	namespace => 'yad_auth'
);

my $refresh_token = $cache->get ('refresh_token');

if (defined $refresh_token) {
	my $token = $oauth->refresh_token ( refresh_token => $refresh_token );
	# yad обычно выдаёт токен на год, скинем с этого 1 минуту :) чтобы уж точно
	$cache->set ('refresh_token', $token->{refresh_token}, 'never');
	$cache->set ('access_token', $token->{access_token}, $token->{expires_in} - 60);
} else {
	die "В локальной базе нет refresh token, возможно, для начала следует запустить yad_get_token.pl";
}

exit 0;

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
