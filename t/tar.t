use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

my $mod = 'Dist::Metadata::Tar';
eval "require $mod" or die $@;

{
  my $ex = exception { $mod->new() };
  like($ex, qr/'file' parameter required/, "new dies without 'file'");
}

my $file = 'corpus/Dist-Metadata-Test-NoMetaFile-0.1.tar.gz';
my $tar = new_ok($mod => [file => $file]);

is($tar->file, $file, 'dumb accessor works');

$tar->determine_name_and_version();
is($tar->name, 'Dist-Metadata-Test-NoMetaFile', 'name from file');
is($tar->version, '0.1', 'version from file');

is(
  $tar->file_content('README'),
  qq[This "dist" is for testing the Tar implementation of Dist::Metadata.\n],
  'got file content without specifying root dir'
);

# perllocale says, "By default Perl ignores the current locale."

is_deeply(
  [sort $tar->find_files],
  [qw(
    Dist-Metadata-Test-NoMetaFile-0.1/README
    Dist-Metadata-Test-NoMetaFile-0.1/lib/Dist/Metadata/Test/NoMetaFile.pm
    Dist-Metadata-Test-NoMetaFile-0.1/lib/Dist/Metadata/Test/NoMetaFile/PM.pm
  )],
  'find_files'
);

is_deeply(
  [sort $tar->list_files],
  [qw(
    README
    lib/Dist/Metadata/Test/NoMetaFile.pm
    lib/Dist/Metadata/Test/NoMetaFile/PM.pm
  )],
  'files listed without root directory'
);

is($tar->root, 'Dist-Metadata-Test-NoMetaFile-0.1', 'root dir');

isa_ok($tar->tar, 'Archive::Tar');

done_testing;
