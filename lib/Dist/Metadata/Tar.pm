# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Tar;
# ABSTRACT: Enable Dist::Metadata for tar files

use Archive::Tar 1 ();   # 0.07 isn't good enough
use Carp (); # core
use parent 'Dist::Metadata::Archive';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

sub file_content {
  my ( $self, $file ) = @_;
  my $re = quotemeta( $self->full_path($file) );
  my($f) = grep { $_->full_path =~ m/^ (?:\.\/)? $re $/x }
    $self->archive->get_files;
  $f ? $f->get_content : undef;
}

sub find_files {
  my ($self) = @_;
  return
    map  { $_->full_path }
    grep { $_->is_file   }
      $self->archive->get_files;
}

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
(actually of L<Dist::Metadata::Archive>)
to enable determining the metadata from a tar file.

This is probably the most useful subclass.

It's probably not very useful on it's own though,
and should be used from L<Dist::Metadata/new>.

=cut
