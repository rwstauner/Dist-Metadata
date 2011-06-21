# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Dir;
# ABSTRACT: Enable Dist::Metadata for a directory

use Carp qw(croak carp);    # core
use File::Find ();          # core
use File::Spec ();          # core
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

=method new

  $dist = Dist::Metadata::Struct->new(dir => $path);

Accepts a single 'dir' argument that should be a path to a directory.

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  # chop trailing slash if present
  $self->{dir} =~ s{/*$}{};

  return $self;
}

sub required_attribute { 'dir' }

=method determine_name_and_version

Attempts to parse name and version from directory name.

=cut

sub determine_name_and_version {
  my ($self) = @_;
  $self->set_name_and_version( $self->parse_name_and_version( $self->dir ) );
  return $self->SUPER::determine_name_and_version();
}

=method dir

Returns the C<dir> attribute specified in the constructor.

=cut

sub dir {
  $_[0]->{dir};
}

# this shouldn't be called
sub extract_into {
  croak q[A directory doesn't need to be extracted];
}

=method file_content

Returns the content for the specified file.

=cut

sub file_content {
  my ($self, $file) = @_;
  my $path = File::Spec->catfile($self->{dir}, $self->full_path($file));

  open(my $fh, '<', $path)
    or croak "Failed to open file '$path': $!";

  return do { local $/; <$fh> };
}

=method find_files

Returns a list of the file names beneath the directory
(relative to the directory).

=cut

sub find_files {
  my ($self) = @_;

  my $dir = $self->{dir};
  my @files;

  File::Find::find(
    {
      wanted => sub {
        push @files, File::Spec->abs2rel($_, $dir)
          if -f $_;
      },
      no_chdir => 1
    },
    $dir
  );

  return @files;
}

=method physical_directory

Returns the C<dir> attribute since this is already a directory
containing the desired files.

=cut

sub physical_directory {
  my ($self) = @_;

  # go into root dir if there is one
  return File::Spec->catdir($self->{dir}, $self->{root})
    if $self->{root};

  return $self->{dir};
}

1;
