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

my $disk = Yandex::Disk->new ( -token => GetAccessToken );
my $remote_dir = $c->{remote_dir};
my $local_dir = $c->{local_dir};

if (substr ($remote_dir, -1) eq '/') {
	chop $remote_dir;
}

if (substr ($remote_dir, 0, 1) eq '/') {
	$remote_dir = substr $remote_dir, 1;
}

if (substr ($local_dir, -1) eq '/') {
	chop $local_dir;
}

# рекурсивненько зааплодим найденные файлы
find (
	{
		wanted => \&wanted,
		no_chdir => 1
	},
	$local_dir
);

sub wanted {
	my $file = $_;
	my %targets;

	if (-f $file) {
		print "Uploading file: $file ... ";
		my $target = substr $file, length ($local_dir) + 1;
		$target = dirname $target;

		if (defined $target && $target ne '' && $target ne '/') {
			$target = sprintf '%s/%s', $remote_dir, $target;
		} else {
			$target = $remote_dir;
		}

		unless (defined $targets{$target}) {
			unless ($disk->createFolder (-path => $target, -recursive => 1)) {
				die "Невозможно создать каталог $c->{remote_dir} на Yandex.Диске\n";
			}

			$targets{$target} = 1;
		}

		$disk->uploadFile (
			-file => $file,
			-remote_path => $target,
			-overwrite => 1
		) or warn "Не могу за-аплодить файл в каталог $remote_dir на Yandex.Диске\n";

		print "done.\n";
	}

	sleep 3;
	return;
}
