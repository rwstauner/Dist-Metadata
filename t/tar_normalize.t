use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Metadata::Tar';
eval "require $mod" or die $@;

my $file = 'corpus/MsqlCGI-0.8.tar.gz';
my $tar = $mod->new(file => $file);

my @files = $tar->perl_files;
is $files[0], 'MsqlCGI-bin/MsqlCGI.pm';

ok $tar->file_content($files[0]);

done_testing;
