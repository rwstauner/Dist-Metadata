# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata;
# ABSTRACT: Information about a perl module distribution

use Archive::Tar;
use Carp qw(croak);
use CPAN::Meta 2.1;
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

=method default_metadata

Returns a hashref of default values
used to intialize a L<CPAN::Meta> object
when a META file is not found.
Called from L</determine_metadata>.

=cut

sub default_metadata {
  my ($self) = @_;

  return {
    # required
    abstract       => undef,
    author         => [],
    dynamic_config => 0,
    generated_by   => ref($self) . ' version ' . $self->VERSION,
    license        => ['unknown'],
    'meta-spec'    => {
      version => '2',
      url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    name           => undef,
    release_status => 'stable',
    version        => undef,

    # optional
    no_index => {
      # ignore test and build directories by default
      directory => [qw( t inc )],
    },
    # provides => { package => { file => $file, version => $version } }
  };
}

=method determine_metadata

Examine the archive and try to determine metadata.
Returns a hashref which can be passed to L<CPAN::Meta/new>.
This is used when the archive does not contain a META file.

=cut

sub determine_metadata {
  my ($self) = @_;

  my $meta = $self->default_metadata;

  if ( my $file = $self->file ) {
    if ( $file =~ m#([^\\/]+)-(v?[0-9._]+)\.tar\.gz$# ) {
      @$meta{qw(name version)} = ( $1, $2 );
    }
  }

  # TODO: determine_provided_packages

  # any passed in values should take priority
  foreach my $field ( keys %$meta ){
    $meta->{$field} = $self->{$field}
      if exists $self->{$field};
  }

  return $meta;
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
    $meta = CPAN::Meta->create(
      $self->determine_metadata,
      { lazy_validation => 1 },
    );
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
