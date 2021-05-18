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

unless (defined $c->{'Код подтверждения'}) {
	# Первый шаг - получение проверочного кода

	say "Шаг 1.\nСсылка для открывания в браузере: \n" . $oauth->get_code();
	say '';
	say 'Код подтверждения надо записать в config.json в параметр "Код подтверждения"';
	say 'Понадобится запустить этот скрипт ещё раз, чтобы занести refresh_token и access_token в локальную базу для работы yadproxy.';
} else {
	# Второй шаг - получение access-токена

	my $token = $oauth->get_token ( code => $c->{'Код подтверждения'} );

	my $cache = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $c->{oauth_dir},
		namespace => 'yad_auth'
	);

	# yad обычно выдаёт токен на год, скинем с этого 1 минуту :) чтобы уж точно
	$cache->set ('refresh_token', $token->{refresh_token}, 'never');
	$cache->set ('access_token', $token->{access_token}, $token->{expires_in} - 60);

	printf "Шаг 2.\nrefresh_token (%s) и access_token (%s) сохранены в базе.\n\n", $token->{refresh_token}, $token->{access_token};
	say 'Можно пользоваться yadproxy.';
}

exit 0;

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
