# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata;
# ABSTRACT: Information about a perl module distribution

1;

=for :stopwords dist

=for test_synopsis
my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);
  my $name = $dist->name;
  my $version = $dist->version;

  my $provides = $dist->module_versions;
  while( my ($module, $version) = each %$provides ){
    print "Dist $name ($version) includes $module $version\n";
  }

=head1 DESCRIPTION

This is sort of a companion to L<Module::Metadata>.
It provides an interface for getting information about a distribution.

This is mostly a wrapper around L<CPAN::Meta>
providing an easy interface to find and load the meta file from a F<tar.gz> file.

If the dist does not contain a meta file
the module will attempt to determine some of that data from the dist.

=cut
