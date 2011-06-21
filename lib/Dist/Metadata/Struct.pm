# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Struct;
# ABSTRACT: Enable Dist::Metadata for a data structure

use Carp qw(croak carp); # core
use File::Spec::Unix;    # core
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

=method new

  $dist = Dist::Metadata::Struct->new(files => {
    'lib/Mod.pm' => 'package Mod; sub { ... }',
    'README'     => 'this is a fake dist, useful for testing',
  });

Accepts a C<files> parameter that should be a hash of
C<< { name => content, } >>.
Content can be a string, a reference to a string, or an IO object.

=cut

sub required_attribute { 'files' }

=method default_file_spec

L<File::Spec::Unix> is the default for consistency/simplicity
but C<file_spec> can be overridden in the constructor.

=cut

sub default_file_spec { 'File::Spec::Unix' }

=method file_content

Returns the string content for the specified name.

=cut

sub file_content {
  my ($self, $file) = @_;
  my $content = $self->{files}{ $self->full_path($file) };

  # 5.10: given(ref($content))

  if( my $ref = ref $content ){
    return $ref eq 'SCALAR'
      # allow a scalar ref
      ? $$content
      # or an IO-like object
      : do { local $/; $content->getline; }
  }
  # else a simple string
  return $content;
}

=method find_files

Returns the keys of the C<files> hash.

=cut

sub find_files {
  my ($self) = @_;

  # place an entry in the hash for consistency with other formats
  $self->{dir} = '';

  return keys %{ $self->{files} };
}

1;
