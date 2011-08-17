# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Archive;
# ABSTRACT: Base class for Dist::Metadata archive files

use Carp (); # core
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

=method new

  $dist = Dist::Metadata::Archive->new(file => $path);

Accepts a single C<file> argument that should be a path to a file.

If called from this base class
C<new()> will delegate to a subclass based on the filename
and return a blessed instance of that subclass.

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  if( $class eq __PACKAGE__ ){
    my $subclass = 'Dist::Metadata::' .
      ( $self->{file} =~ /\.zip$/ ? 'Zip' : 'Tar' );

    eval "require $subclass"
      or Carp::croak $@;

    # rebless into format specific subclass
    bless $self, $subclass;
  }

  return $self;
}

sub required_attribute { 'file' }

=method archive

Returns an object representing the archive file.

=cut

sub archive {
  my ($self) = @_;
  return $self->{archive} ||= do {
    my $file = $self->file;

    Carp::croak "File '$file' does not exist"
      unless -e $file;

    $self->read_archive($file); # return
  };
}

=method default_file_spec

Returns C<Unix> since most archive files are be in unix format.

=cut

sub default_file_spec { 'Unix' }

=method determine_name_and_version

Attempts to parse name and version from file name.

=cut

sub determine_name_and_version {
  my ($self) = @_;
  $self->set_name_and_version( $self->parse_name_and_version( $self->file ) );
  return $self->SUPER::determine_name_and_version(@_);
}

=method file

The C<file> attribute passed to the constructor,
used to load L</archive>.

=cut

sub file {
  return $_[0]->{file};
}


1;

=for test_synopsis
my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
to enable determining the metadata from an archive file.

It is a base class for archive file formats:

=for :list
* L<Dist::Metadata::Tar>
* L<Dist::Metadata::Zip>

It's not useful on it's own
and should be used from L<Dist::Metadata/new>.

=cut
