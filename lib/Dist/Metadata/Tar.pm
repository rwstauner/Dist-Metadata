# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Tar;
# ABSTRACT: Enable Dist::Metadata for tar files

use Archive::Tar 1 ();   # 0.07 isn't good enough
use Carp (); # core
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

=method new

  $dist = Dist::Metadata::Tar->new(file => $path);

Accepts a single C<file> argument that should be a path to a F<tar.gz> file.

=cut

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

Returns C<Unix> since tar files must be in unix format.

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

=method file_content

Returns the content for the specified file.

=cut

sub file_content {
  my ( $self, $file ) = @_;
  return $self->archive->get_content( $self->full_path($file) );
}

=method find_files

Returns a list of regular files in the archive.

=cut

sub find_files {
  my ($self) = @_;
  return
    map  { $_->full_path }
    grep { $_->is_file   }
      $self->archive->get_files;
}

=method read_archive

  $dist->read_archive($file);

Returns an L<Archive::Tar> object representing the specified file.

=cut

sub read_archive {
  my ($self, $file) = @_;

  my $archive = Archive::Tar->new();
  $archive->read($file);

  return $archive;
}

sub tar {
  warn __PACKAGE__ . '::tar() is deprecated.  Use archive() instead.';
  return $_[0]->archive;
}

1;

=for Pod::Coverage tar

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
