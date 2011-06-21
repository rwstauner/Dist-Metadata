# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Tar;
# ABSTRACT: Enable Dist::Metadata for tar files

use Archive::Tar ();
use Carp qw(croak carp); # core
use File::Spec::Unix (); # core
use Try::Tiny 0.09;
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

=method new

  $dist = Dist::Metadata::Tar->new(file => $path);

Accepts a single C<file> argument that should be a path to a F<tar.gz> file.

=cut

sub required_attribute { 'file' }

=method default_file_spec

Returns L<File::Spec::Unix> since tar files must be in unix format.

=cut

sub default_file_spec { 'File::Spec::Unix' }

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
used to load L</tar>.

=cut

sub file {
  return $_[0]->{file};
}

=method file_content

Returns the content for the specified file.

=cut

sub file_content {
  my ( $self, $file ) = @_;
  return $self->tar->get_content( $self->full_path($file) );
}

=method find_files

Returns a list of regular files in the archive.

=cut

sub find_files {
  my ($self) = @_;
  return
    map  { $_->full_path }
    grep { $_->is_file   }
      $self->tar->get_files;
}

=method tar

Returns the L<Archive::Tar> object in use (loaded from the C<file> attribute).

=cut

sub tar {
  my ($self) = @_;
  return $self->{tar} ||= do {
    my $file = $self->file;

    croak "File '$file' does not exist"
      unless -e $file;

    my $tar = Archive::Tar->new();
    $tar->read($file);

    $tar; # return
  };
}

1;

=for test_synopsis
my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
to enable determining the metadata from a tar file.

This is probably the most useful subclass.

It's probably not very useful on it's own though,
and should be used from L<Dist::Metadata/new>.

=cut
