# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata::Struct;
# ABSTRACT: Enable Dist::Metadata for a data structure

use Carp qw(croak carp); # core
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

=method new

  $dist = Dist::Metadata::Struct->new(files => {
    'lib/Mod.pm' => 'package Mod; sub something { ... }',
  });

Accepts a C<files> parameter that should be a hash of
C<< { name => content, } >>.
Content can be a string, a reference to a string, or an IO object.

=cut

sub required_attribute { 'files' }

=method default_file_spec

C<Unix> is the default for consistency/simplicity
but C<file_spec> can be overridden in the constructor.

=cut

sub default_file_spec { 'Unix' }

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

  return keys %{ $self->{files} };
}

1;

=head1 SYNOPSIS

  my $dm = Dist::Metadata->new(struct => {
    files => {
      'lib/Mod.pm' => 'package Mod; sub something { ... }',
      'README'     => 'this is a fake dist, useful for testing',
    }
  });

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
to enable mocking up a dist from perl data structures.

This is mostly used for testing
but might be useful if you already have an in-memory representation
of a dist that you'd like to examine.

It's probably not very useful on it's own though,
and should be used from L<Dist::Metadata/new>.

=cut
