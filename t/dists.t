use strict;
use warnings;
use Test::More 0.96;
use Path::Class 0.24;

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;

# we may need to prepend $FindBin::Bin
my $root = 'corpus';
my $structs = do "$root/structs.pl";

# NOTE: Portability tests report issues with file names being long
# and containing periods, so there could be issues...

foreach my $test  (
  [
    [
      metafile =>
      'Dist-Metadata-Test-MetaFile-2.2',
    ],
    {
      name     => 'Dist-Metadata-Test-MetaFile',
      version  => '2.2',
      provides => {
        'Dist::Metadata::Test::MetaFile' => {
          file    => 'lib/Dist/Metadata/Test/MetaFile.pm',
          version => '2.1',
        },
        'Dist::Metadata::Test::MetaFile::PM' => {
          file    => 'lib/Dist/Metadata/Test/MetaFile/PM.pm',
          version => '2.0',
        },
      },
    },
  ],
  [
    [
      nometafile =>
      'Dist-Metadata-Test-NoMetaFile-0.1',
    ],
    {
      name     => 'Dist-Metadata-Test-NoMetaFile',
      version  => '0.1',
      provides => {
        'Dist::Metadata::Test::NoMetaFile' => {
          file    => 'lib/Dist/Metadata/Test/NoMetaFile.pm',
          version => '0.1',
        },
        'Dist::Metadata::Test::NoMetaFile::PM' => {
          file    => 'lib/Dist/Metadata/Test/NoMetaFile/PM.pm',
          version => '0.1',
        },
      },
    },
  ],
  [
    [
      subdir =>
      'Dist-Metadata-Test-SubDir-1.5.tar.gz',
      'subdir',
    ],
    {
      name     => 'Dist-Metadata-Test-SubDir',
      version  => '1.5',
      provides => {
        'Dist::Metadata::Test::SubDir' => {
          file    => 'lib/Dist/Metadata/Test/SubDir.pm',
          version => '1.1',
        },
        'Dist::Metadata::Test::SubDir::PM' => {
          file    => 'lib/Dist/Metadata/Test/SubDir/PM.pm',
          version => '1.0',
        },
      },
    },
  ],
  [
    'noroot',
    {
      # can't guess name/version without formatted file name or root dir
      name     => Dist::Metadata::UNKNOWN(),
      version  => '0',
      provides => {
        'Dist::Metadata::Test::NoRoot' => {
          file    => 'lib/Dist/Metadata/Test/NoRoot.pm',
          version => '3.3',
        },
        'Dist::Metadata::Test::NoRoot::PM' => {
          file    => 'lib/Dist/Metadata/Test/NoRoot/PM.pm',
          version => '3.25',
        },
      },
    },
  ],
){
  my ( $dists, $exp ) = @$test;
  $exp->{package_versions} = do {
    my $p = $exp->{provides};
    +{ map { ($_ => $p->{$_}{version}) } keys %$p };
  };

  $dists = [ ($dists) x 2 ]
    unless ref $dists;

  my ($key, $file, $dir) = @$dists;
  
  if ( !$dir ) {
    ($file, $dir) = ("$file.tar.gz", $file);
  }
  $_ = "corpus/$_" for ($file, $dir);

  $_ = file($root, $_)->stringify
    for @$dists;

  foreach my $args (
    [file => $file],
    [dir  => $dir],
    [struct => { files => $structs->{$key} }],
  ){
    my $dm = new_ok( $mod, $args );

    is_deeply( $dm->$_, $exp->{$_}, "verify $_ for @$args" )
      for keys %$exp;
  }
}

done_testing;
