use strict;
use warnings;
use Test::MockObject 1.09;

use Exporter qw(import);
our @EXPORT = qw(
  fake_archive
);

sub fake_archive {
  my $tmo = Test::MockObject->new( {@_} );
  $tmo->set_list( list_files => keys %{ $tmo->{files} } );
  $tmo->mock( get_content => sub { $_[0]->{files}->{ $_[1] } } );
  return $tmo;
}
