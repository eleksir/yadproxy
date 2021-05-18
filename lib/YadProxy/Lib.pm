package YadProxy::Lib;
# Утилитарные функции для работы с ya.disk

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );

use CHI;
use CHI::Driver::BerkeleyDB;
use Log::Any qw ($log);
use YadProxy::Conf qw (LoadConf);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (GetAccessToken RefreshAccessToken);


my $c = LoadConf ();

sub GetAccessToken {
	my $cache = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $c->{oauth_dir},
		namespace => 'yad_auth'
	);

	my $access_token = $cache->get ('access_token');

	unless (defined $access_token) {
		my $refresh_token = $cache->get ('refresh_token');

		unless (defined $refresh_token) {
			$log->fatal ("No refresh_token found in base, please, register yaproxy application");
			exit 1;
		}

		my $token = RefreshAccessToken ($refresh_token);
        # yad обычно выдаёт токен на год, скинем с этого 1 минуту :) чтобы уж точно
		$cache->set ('refresh_token', $token->{refresh_token}, 'never');
		$cache->set ('access_token', $token->{access_token}, $token->{expires_in} - 60);
		$access_token = $token->{access_token};
	}

	return $access_token;
}

sub RefreshAccessToken {
	my $refresh_token = shift;

	my $oauth = Yandex::OAuth->new (
		client_id     => $c->{ID},
		client_secret => $c->{'Пароль'},
	);

	my $token;
	my $counter = 0;

	while ((! defined $token->{access_token}) || ($counter < 3)) {
		$token = $oauth->refresh_token ( refresh_token => $refresh_token );
		$counter++;
	}

	if (defined $token->{access_token}) {
		return $token;
	} else {
		$log->fatal ("[FATAL] Unable to refresh access_token");
		exit 1;
	}
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
