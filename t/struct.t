use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;
use Test::MockObject 1.09 ();

my $mod = 'Dist::Metadata::Struct';
eval "require $mod" or die $@;

# required_attribute
{
  my $att = 'files';
  is( $mod->required_attribute, $att, "'$att' attribute required" );
  my $ex = exception { $mod->new() };
  like( $ex, qr/'$att' parameter required/, "new dies without '$att'" );
}

# don't create a dependency on IO::String or IO::Scalar for this simple test.
my $io = Test::MockObject->new({});
$io->mock(getline => sub { 'read me' });

# file_content
# find_files
foreach my $test (
  [ string     =>  'read me' ],
  [ scalar_ref => \'read me' ],
  [ io         =>       $io  ],
) {
  my ( $type, $content ) = @$test;
  my $dist = new_ok( $mod, [ files => { README => $content } ] );
  is( $dist->file_content('README'), 'read me', "content returned for $type" );
  is_deeply( [ $dist->find_files ], ['README'], 'all files listed' );
}

# default_file_spec
# file_spec
# find_files
# determine_packages
{
  my $defspec = 'Unix';
  my $spec = 'Win32';
  my $dist = new_ok($mod, [file_spec => $spec, files => {
    README => 'nevermind',
    'lib\\Mod\\Name.pm' => "package Mod::Name;\nour \$VERSION = 0.11;"
  }]);
  is( $dist->default_file_spec, $defspec, "struct defaults to $defspec" );
  is( $dist->file_spec,         $spec,    "struct has custom spec: $spec" );

  # TODO: should paths always come out in unix format?  perhaps not if you specify an alternate...
  is_deeply( [sort $dist->find_files], ['README', 'lib\\Mod\\Name.pm'], 'all files listed' );

  is_deeply( $dist->determine_packages, {'Mod::Name' => {file => 'lib/Mod/Name.pm', version => '0.11'}},
    'determined package with translated path' );
}

# TODO: test w/ file_spec => ''

done_testing;
