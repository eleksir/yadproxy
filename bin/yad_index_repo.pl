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
use File::Basename qw (basename dirname);
use File::Find qw (find);
use YadProxy::Conf qw (LoadConf);
use YadProxy::Lib qw (GetAccessToken);
use Yandex::Disk;

my $c = LoadConf ();
my $remote_dir = $c->{remote_dir};
my $index_dir = $c->{index_dir};

my $index_url = CHI->new (
        driver => 'BerkeleyDB',
        root_dir => $index_dir,
        namespace => 'url'
);

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

my $disk = Yandex::Disk->new ( -token => GetAccessToken );


if (substr ($remote_dir, -1) eq '/') {
	chop $remote_dir;
}

if (substr ($remote_dir, 0, 1) eq '/') {
	$remote_dir = substr $remote_dir, 1;
}

unless (substr ($remote_dir, 0, 6) eq 'disk:/') {
	$remote_dir = sprintf 'disk:/%s/', $remote_dir;
}

my $list = $disk->listAllFiles ( -path => 'REPO' ); # Note that this will give us first 999999 files
my $pattern = qr /$remote_dir/;

my %month = (
	'01' => 'Jan',
	'02' => 'Feb',
	'03' => 'Mar',
	'04' => 'Apr',
	'05' => 'May',
	'06' => 'Jun',
	'07' => 'Jul',
	'08' => 'Aug',
	'09' => 'Sep',
	'10' => 'Oct',
	'11' => 'Nov',
	'12' => 'Dec'
);

foreach (@{$list}) {
	my $filename = $_->{path};

	if ($filename =~ m/$pattern(.+)/) {
		$filename = $1;

		if (defined $filename) {
			if (defined $_->{file} && defined $_->{size} && defined $_->{md5} && defined $_->{sha256} && defined $_->{modified}) {
				$index_url->set    ($filename, $_->{file},     'never');
				$index_size->set   ($filename, $_->{size},     'never');
				$index_md5->set    ($filename, $_->{md5},      'never');
				$index_sha256->set ($filename, $_->{sha256},   'never');

				my $time = sprintf (
					'%s-%s-%s %s:%s',
					substr ($_->{modified}, 8, 2),
					$month{substr ($_->{modified}, 5, 2)},
					substr ($_->{modified}, 0, 4),
					substr ($_->{modified}, 11, 2),
					substr ($_->{modified}, 14, 2)
				);

				$index_mtime->set  ($filename, $time,          'never');
				my $dir = dirname $filename;

				if (defined $dir && $dir ne '' && $dir ne '.') {
					my @dirs = split (/\//, $dir);

					do {
						unless (defined $index_dirs->get (join '/', @dirs)) {
							$index_dirs->set (join ('/', @dirs), 1, 'never');
						}
					} while (pop @dirs);
				}

			} else {
				warn "Yandex.Диск API вернуло неполные данные для $filename";
			}
		}
	}
}
