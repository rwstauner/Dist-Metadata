# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Dir;
# ABSTRACT: Enable Dist::Metadata for a directory

use Carp qw(croak carp);    # core
use File::Find ();          # core
use Path::Class 0.24 ();
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

=method new

  $dist = Dist::Metadata::Struct->new(dir => $path);

Accepts a single 'dir' argument that should be a path to a directory.

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  # fix up dir (for example chop trailing slash if present)
  $self->{dir} = $self->path_class_dir->new($self->{dir})->stringify;

  # TODO: croak if not -d $self->dir

  return $self;
}

sub required_attribute { 'dir' }

=method determine_name_and_version

Attempts to parse name and version from directory name.

=cut

sub determine_name_and_version {
  my ($self) = @_;
  # 'root' may be more accurate than 'dir'
  $self->SUPER::determine_name_and_version();
  $self->set_name_and_version( $self->parse_name_and_version( $self->dir ) );
  return;
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
  # This is a directory so file spec will always be native
  my $path = $self->path_class_file
    ->new( $self->{dir}, $self->full_path($file) )->stringify;

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
        push @files, $self->path_class_file->new($_)->relative($dir)->stringify
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
  return $self->path_class_dir->new($self->{dir}, $self->{root})->stringify
    if $self->{root};

  return $self->{dir};
}

1;

=for test_synopsis
my $path_to_dir;

=head1 SYNOPSIS

  my $dm = Dist::Metadata->new(dir => $path_to_dir);

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
to enable getting the dists metadata from a directory.

This can be useful if you already have a dist extracted into a directory.

It's probably not very useful on it's own though,
and should be used from L<Dist::Metadata/new>.

=cut
