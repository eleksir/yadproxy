package YadProxy;
# Выдаёт листинг каталогов в стиле nginx и редиректы для файлов

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use CHI;
use CHI::Driver::BerkeleyDB;
use File::Basename qw (basename dirname);
use List::SomeUtils qw (any);
use YadProxy::Conf qw (LoadConf);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (DirList);

my $c = LoadConf ();
my $index_dir = $c->{index_dir};
my $url_prefix = $c->{url_prefix};


sub DirList {
	my $requested_path = shift;

	if ((! defined $requested_path) || $requested_path eq '') {
		$requested_path = '/';
	} else {
		while (substr ($requested_path, -1) eq '/') {
			chop $requested_path;
		}

		if ((! defined $requested_path) || $requested_path eq '') {
			$requested_path = '/';
		}
	}

	my @output;
	my @found;
	my $status = '200';
	my $content_type = 'text/plain';

	my $index_url = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $index_dir,
		namespace => 'url'
	);

	# прежде чем строить индекс, проверим-ка мы запрос на вшивость, вдруг, с нас запрашивают файл?
	# в этом случае нам надо отдать 302
	if (my $url = $index_url->get ($requested_path)) {
		return ('302', 'text/plain', $url);
	}

	my $index_size = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $index_dir,
		namespace => 'size'
	);

	my $index_md5 = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $index_dir,
		namespace => 'md5'
	);

	my $index_sha256 = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $index_dir,
		namespace => 'sha256'
	);

	my $index_dirs = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $index_dir,
		namespace => 'dirs'
	);

	my $index_mtime = CHI->new (
		driver => 'BerkeleyDB',
		root_dir => $index_dir,
		namespace => 'mtime'
	);

	my $index_of;

	if ($requested_path eq '/') {
		$index_of = $url_prefix;
	} else {
		$index_of = $url_prefix . '/' . $requested_path;
	}

	if (substr ($url_prefix, 0, 1) ne '/') {
		$index_of = '/' . $index_of;
	}

	push @output, "<html>";
	push @output, sprintf '<head><title>Index of %s/</title></head>', $index_of;
	push @output, "<body>";
	push @output, sprintf '<h1>Index of %s/</h1><hr><pre><a href="../">../</a>', $index_of;

	# попробуем отловить все каталоги, начинающиеся с запрошенного пути
	foreach my $key (sort ($index_dirs->get_keys ())) {
		if (
			(
				(defined $key) &&
				(length ($key) > length ($requested_path)) &&
				(substr ($key, 0, length ($requested_path)) eq $requested_path)
			) ||
			$requested_path eq '/'
		) {
			my @dirs;

			if ($requested_path eq '/') {
				@dirs = split /\//, $key;
			} else {
				@dirs = split /\//, substr ($key, 1 + length ($requested_path));
			}

			if (defined $dirs[0] && (! any {$_ eq $dirs[0]} @found)) {
				# у каталогов нету ctime или mtime, так что поставим 01-Jan-1970 00:00
				push @found, $dirs[0];
				my $str = $dirs[0];
				my $len = 50 - (1 + length ($str));

				if ($len < 0) {
					$str = substr ($str, 0, 47);
					$str .= '...';
					$len = 0;
				}

				# there is no way to get dir mtime from yandex.disk
				push @output, sprintf (
					"<a href=\"%s/\">%s/</a>% ${len}s 01-Jan-1970 00:00                   -",
					$dirs[0],
					$str,
					''
				);
			}
		}
	}

	# попробуем отловить все файлы, начинающиеся с запрошенного пути
	foreach my $key (sort ($index_url->get_keys())) {
		if (
			(
				(defined $key) &&
				(length ($key) > length ($requested_path)) &&
				(substr ($key, 0, length ($requested_path)) eq $requested_path)
			) ||
			$requested_path eq '/'
		) {
			my $str;
			my @urls;

			if ($requested_path eq '/') {
				@urls = split /\//, $key;
			} else {
				@urls = split /\//, substr ($key, 1 + length ($requested_path));
			}

			if (defined $urls[0] && (! any {$_ eq $urls[0]} @found)) {
				push @found, $urls[0];
				$str = $urls[0];
			}

			if ($#urls < 1) {
				my $len = 50 - length ($str);

				if ($len < 0) {
					$str = substr ($str, 0, 47);
					$str .= '...';
					$len = 0;
				}

				push @output, sprintf (
					"<a href=\"%s/\">%s</a>% ${len}s %s % 19s",
					$index_url->get ($key),
					$str,
					'',
					$index_mtime->get ($key),
					$index_size->get ($key)
				);
			}
		}
	}

	push @output, "</pre><hr></body>";
	push @output, "</html>";
	return ('200', 'text/html', join "\n", @output);
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
