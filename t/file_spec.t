use strict;
use warnings;
use Test::More 0.96;

require Dist::Metadata::Struct;

# all these translate into "Native"
foreach my $test (
  [ '' => 'Native' ],
  [ qw( File::Spec         Native ) ],
  [ qw( File::Spec::Native Native ) ],
  [ qw(             Native Native ) ],
  [ qw(             Win32  Win32  ) ],
  [ qw( File::Spec::Win32  Win32  ) ],
) {
  my ( $spec, $exp ) = @$test;
  my $dist = new_ok( 'Dist::Metadata::Struct', [ file_spec => $spec, files => {} ] );
  is( $dist->file_spec, $exp, "spec '$spec' => '$exp'" );
}

done_testing;
