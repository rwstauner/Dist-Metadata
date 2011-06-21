use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Metadata::Struct';
eval "require $mod" or die $@;

{
  foreach my $test (
    [
      '/tmp/No-Existy-1.01',
      [],
      ['No-Existy', '1.01'],
      undef # same
    ],
    [
      # main module: No::Existy::3 (like perl5i::2)
      'No-Existy-3-v2.1.3',
      [],
      ['No-Existy-3', 'v2.1.3'],
      undef # same
    ],
    [
      # constructor args override
      'No-Existy-3-v2.1.3',
      [
        name => 'Who-Cares'
      ],
      ['No-Existy-3', 'v2.1.3'],
      ['Who-Cares',   'v2.1.3'],
    ],
    [
      # constructor args override
      'No-Existy-3-v2.1.3',
      [
        name => 'Who-Cares',
        version => 5,
      ],
      ['No-Existy-3', 'v2.1.3'],
      ['Who-Cares',   '5'],
    ],
  ){
    my ($base, $args, $parsed, $att) = @$test;
    $att ||= $parsed;
    # test dir name and tar file name
    foreach my $path ( $base, "$base.tar.gz", "$base.tgz" ){
      my $dm = new_ok($mod, [files => {}, @$args]);

      my @nv = $dm->parse_name_and_version($path);
      is_deeply(\@nv, $parsed, 'parsed name and version');

      $dm->set_name_and_version(@nv);
      is_deeply([$dm->name, $dm->version], $att, "set dist name and version");
    }
  }
}

done_testing;
