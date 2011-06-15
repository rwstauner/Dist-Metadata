# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata;
# ABSTRACT: Information about a perl module distribution

use Carp qw(croak);
use CPAN::Meta;
use Archive::Tar;
use List::Util qw(first);    # core in perl v5.7.3

#use Module::Metadata;

=method new

  Dist::Metadata->new(file => $path);

Constructor.

Accepts a single 'file' argument that should be a path to a F<tar.gz> file.

=cut

sub new {
  my $class = shift;
  my $self  = {
    @_ == 1 ? %{ $_[0] } : @_
  };

  bless $self, $class;

  croak q['file' parameter not supplied]
    unless $self->{file} || $self->{archive};

  return $self;
}

=method archive

Returns the archive object (loaded from L</file>).

=cut

sub archive {
  my ($self) = @_;
  return $self->{archive} ||= do {
    my $file = $self->file;

    croak "File '$file' does not exist"
      unless -e $file;

    my $tar = Archive::Tar->new();
    $tar->read($file);

    $tar; # return
  };
}

=method file

Returns the 'file' parameter passed to the constructor.
Should be the path to an archive file.

=cut

sub file {
  return $_[0]->{file};
}

=method load_meta

Loads the metadata from the L</file>.

=cut

sub load_meta {
  my ($self) = @_;

  my $archive = $self->archive;
  my @files   = $archive->list_files;
  my ($meta, $metafile);

  # prefer json file
  if ( $metafile = first { m#^([^/]+/)?META\.json$# } @files ) {
    $meta = CPAN::Meta->load_json_string( $archive->get_content($metafile) );
  }
  elsif ( $metafile = first { m#^([^/]+/)?META\.ya?ml$# } @files ) {
    $meta = CPAN::Meta->load_yaml_string( $archive->get_content($metafile) );
  }
  # no META file found in archive
  else {
    croak('TODO: determine basic metadata when META file not found');
  }

  return $meta;
}

=method meta

Returns the L<CPAN::Meta> instance in use.

=cut

sub meta {
  my ($self) = @_;
  return $self->{meta} ||= $self->load_meta;
}

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
