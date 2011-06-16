use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use DM_Tester;

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;

{
  foreach my $test (
    [
      [
        file => '/tmp/No-Existy-1.01.tar.gz',
        archive => fake_archive( files => {} ),
      ],
      {
        name => 'No-Existy',
        version => '1.01'
      },
    ],
    [
      # main module: No::Existy::3 (like perl5i::2)
      [
        file => 'No-Existy-3-v2.1.3.tar.gz',
        archive => fake_archive( files => {} ),
      ],
      {
        name => 'No-Existy-3',
        version => 'v2.1.3'
      },
    ],
    [
      # constructor args override
      [
        name => 'Who-Cares',
        file => 'No-Existy-3-v2.1.3.tar.gz',
        archive => fake_archive( files => {} ),
      ],
      {
        name => 'Who-Cares',
        version => 'v2.1.3'
      },
    ],
    [
      # constructor args override
      [
        name => 'Who-Cares',
        version => 5,
        file => 'No-Existy-3-v2.1.3.tar.gz',
        archive => fake_archive( files => {} ),
      ],
      {
        name => 'Who-Cares',
        version => '5'
      },
    ],
  ){

    my ($args, $exp) = @$test;
    my $distmeta = new_ok($mod, $args);

    is($distmeta->$_, $exp->{$_}, "determined dist $_")
      for keys %$exp;
  }
}

done_testing;
