# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Zip;
# ABSTRACT: Enable Dist::Metadata for zip files

use Archive::Zip 1.30 ();
use Carp (); # core

use parent 'Dist::Metadata::Archive';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

sub file_content {
  my ($self, $file) = @_;
  my ($content, $status) = $self->archive->contents( $self->full_path($file) );
  Carp::croak "Failed to get content of '$file' from archive"
    if $status != Archive::Zip::AZ_OK();
  return $content;
}

sub find_files {
  my ($self) = @_;
  return
    map  {  $_->fileName    }
    grep { !$_->isDirectory }
      $self->archive->members;
}

sub read_archive {
  my ($self, $file) = @_;

  my $archive = Archive::Zip->new();
  $archive->read($file) == Archive::Zip::AZ_OK()
    or Carp::croak "Failed to read zip file!";

  return $archive;
}

1;

=for test_synopsis
my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
(actually of L<Dist::Metadata::Archive>)
to enable determining the metadata from a zip file.

It's probably not very useful on it's own
and should be used from L<Dist::Metadata/new>.

=cut
