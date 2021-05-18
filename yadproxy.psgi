use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use version; our $VERSION = qw (1.1.0);

use lib qw (./lib ./vendor_perl/lib/perl5);
use YadProxy qw (DirList);
use YadProxy::Conf qw (LoadConf);

my $c = LoadConf ();
my $url_prefix = $c->{url_prefix};

if (substr ($url_prefix, -1) eq '/') {
	chop $url_prefix;
}

if (substr ($url_prefix, 0, 1) eq '/') {
	$url_prefix = substr $url_prefix, 1;
}

my $app = sub {
	my $env = shift;

	my $msg = "<html>\n<head><title>404 Not Found</title></head>\n<body>\n<center><h1>404 Not Found</h1></center>\n</body>\n</html>\n";
	my $status = '404';
	my $content = 'text/html';

	if ($env->{PATH_INFO} =~ m/^\/$url_prefix\/(.*)/) {
		my $path = $1;

		($status, $content, $msg) = DirList ($path);
	}

	if ($status eq '302') {
		my $message = << "EOM";
<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
</body>
</html>
EOM
		use bytes;
		my $length = length $message;
		no bytes;

		return [
			$status,
			[
				'Content-Type' => $content,
				'Content-Length' => $length,
				'Location' => $msg
			],
			[$message]
		];
	}

	use bytes;
	my $length = length $msg;
	no bytes;

	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => $length ],
		[ $msg ],
	];
};


__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
