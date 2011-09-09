use strict;
use warnings;
use Test::More 0.96;
use Path::Class qw( foreign_file );

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;

# specifically test that expected paths are not indexed on various platforms
foreach my $spec ( qw(Unix Win32 Mac) ){
  my $dm = new_ok($mod, [struct => {
    file_spec => $spec, 
    files => {
      README => 'nevermind',
      foreign_file($spec => qw(lib Mod Name.pm)) => "package Mod::Name;\nour \$VERSION = 0.11;",
      foreign_file($spec => qw(inc No.pm))       => "package No;\nour \$VERSION = 0.11;",
      foreign_file($spec => qw(t lib YU.pm))     => "package YU;\nour \$VERSION = 0.11;",
    }
  }]);

  is $dm->dist->file_spec, $spec, "dist faking file spec: $spec";

  is_deeply
    [sort $dm->dist->perl_files],
    [sort grep { !/README/ } keys %{ $dm->dist->{files} }],
    'perl files listed';

  is_deeply
    $dm->package_versions,
    {'Mod::Name' => '0.11'},
    't and inc not indexed';

  is_deeply
    $dm->determine_packages,
    {'Mod::Name' => {file => 'lib/Mod/Name.pm', version => '0.11'}},
    'determined package with translated path';
}

done_testing;
