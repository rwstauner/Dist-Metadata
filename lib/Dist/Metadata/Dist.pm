use strict;
use warnings;

package Dist::Metadata::Dist;
# ABSTRACT: Base class for format-specific implementations

use Carp qw(croak carp);     # core
use File::Spec ();           # core
use Try::Tiny 0.09;

=method new

Simple constructor that subclasses can inherit.
Ensures the presence of L</required_attribute>
if defined by the subclass.

=cut

sub new {
  my $class = shift;
  my $self  = {
    @_ == 1 ? %{ $_[0] } : @_
  };

  bless $self, $class;

  my $req = $class->required_attribute;
  croak qq['$req' parameter required]
    if $req && !$self->{$req};

  return $self;
}

=method default_file_spec

Defaults to C<File::Spec> in the base class.
See L</file_spec>.

=cut

sub default_file_spec { 'File::Spec' }

=method determine_name_and_version

Some dist formats may define a way to determine the name and version.

=cut

sub determine_name_and_version {
  my ($self) = @_;
  $self->set_name_and_version( $self->parse_name_and_version( $self->root ) );
  return;
}

=method determine_packages

  $packages = $dist->determine_packages(@files);

Search the specified files (or all files if unspecified)
for perl packages.

Extracts the files to a temporary directory if necessary
and uses L<Module::Metadata> to discover package names and versions.

=cut

sub determine_packages {
  my ($self, @files) = @_;

  my $determined = try {
    my $dir = $self->physical_directory(@files);

    # return
    $self->packages_from_directory($dir, @files);
  }
  catch {
    carp("Error determining packages: $_[0]");
    +{}; # return
  };

  return $determined;
}

=method extract_into

  $dist->extract_into($dir, @files);

Extracts the specified files (or all files if not specified)
into the specified directory.

=cut

sub extract_into {
  my ($self, $dir, @files) = @_;

  @files = $self->list_files
    unless @files;

  require File::Path;
  require File::Basename;

  foreach my $file (@files) {
    my $path = File::Spec->catfile($dir, $file);

    # legacy interface (should be compatible with whatever version is installed)
    File::Path::mkpath( File::Basename::dirname($path), 0, oct(700) );

    open(my $fh, '>', $path)
      or croak "Failed to open '$path' for writing: $!";
    print $fh $self->file_content($file);
  }

  return $dir;
}

=method file_content

Returns the content for the specified file from the dist.
Must be defined by subclasses.

=cut

sub file_content {
  croak q[Method 'file_content' not defined];
}

=method find_files

Determine the files contained in the dist.

This is called from L</list_files> and cached on the object.

=cut

sub find_files {
  croak q[Method 'find_files' not defined];
}

=method file_spec

Returns the class name of the L<File::Spec> module used for this format.
This is mostly so subclasses can define a specific one if necessary.

A C<file_spec> attribute can be passed to the constructor
to override the default.

B<NOTE>: This is used for the internal format of the dist.
Tar archives, for example, are always in unix format.
For operations outside of the dist, L<File::Spec> will always be used.

=cut

sub file_spec {
  return $_[0]->{file_spec} ||= $_[0]->default_file_spec;
}

=method full_path

  $dist->full_path("lib/Mod.pm"); # "root-dir/lib/Mod.pm"

Used internally to put the L</root> directory back onto the file.

=cut

sub full_path {
  my ($self, $file) = @_;

  return $file
    unless my $root = $self->root;

  # don't re-add the root if it's already there
  return $file
    # FIXME: this regexp is probably not cross-platform...
    # FIXME: is there a way to do this with File::Spec?
    if $file =~ m@^\Q${root}\E[\\/]@;

  return $self->file_spec->catfile($root, $file);
}

=method list_files

Returns a list of the files in the dist starting at the dist root.

This calls L</find_files> to get a listing of the contents of the dist,
determines (and caches) the root directory (if any),
caches and returns the the list of files with the root dir stripped.

  @files = $dist->list_files;
  # something like qw( README META.yml lib/Mod.pm )

=cut

sub list_files {
  my ($self) = @_;

  $self->{_list_files} = do {
    my @files = sort $self->find_files;
    my ($root, @rel) = $self->remove_root_dir(@files);
    $self->{root} = $root;
    \@rel; # return
  }
    unless $self->{_list_files};

  return @{ $self->{_list_files} };
}

=method name

The dist name if it could be determined.

=cut

{
  no strict 'refs'; ## no critic (NoStrict)
  foreach my $method ( qw(
    name
    version
  ) ){
    *$method = sub {
      my ($self) = @_;

      $self->determine_name_and_version
        if !exists $self->{ $method };

      return $self->{ $method };
    };
  }
}

=method packages_from_directory

  $provides = $dist->packages_from_directory($dir, @files);

Determines the packages provided by the perl modules found in a directory.
This is thin wrapper around
L<Module::Metadata/package_versions_from_directory>.
It returns a hashref like L<CPAN::Meta::Spec/provides>.

=cut

sub packages_from_directory {
  my ($self, $dir, @files) = @_;

  require Module::Metadata;

  my $provides = try {
    # M::M::p_v_f_d expects full paths for \@files
    Module::Metadata->package_versions_from_directory($dir,
      # FIXME: $self->file_spec->splitpath($_) (write tests first)
      [map { File::Spec->catfile($dir, $_) } @files]
    );
  }
  catch {
    carp("Failed to determine packages: $_[0]");
    +{}; # return
  };
  return $provides || {};
}

=method parse_name_and_version

  ($name, $version) = $dist->parse_name_and_version($path);

Attempt to parse name and version from the provided string.
This will work for dists named like "Dist-Name-1.0".

=cut

sub parse_name_and_version {
  my ($self, $path) = @_;
  my ( $name, $version );
  if ( $path ){
    $path =~ m!
      ([^\\/]+)             # name (anything below final directory)
      -                     # separator
      (v?[0-9._]+)          # version
      (?:                   # possible file extensions
          \.t(?:ar\.)?gz
      )?
      $
    !x and
      ( $name, $version ) = ( $1, $2 );
  }
  return ($name, $version);
}


=method perl_files

Returns the subset of L</list_files> that look like perl files.
Currently returns anything matching C<\.pm$>

TODO: This should probably be customizable.

=cut

sub perl_files {
  return
    grep { /\.pm$/ }
    $_[0]->list_files;
}

=method physical_directory

Returns the path to a physical directory on the disk
where the specified files can be found.

For in-memory formats this will make a temporary directory
and write the specified files (or all files) into it.

=cut

sub physical_directory {
  my ($self, @files) = @_;

  require   File::Temp;
  # dir will be removed when return value goes out of scope (in caller)
  my $dir = File::Temp->newdir();

  $self->extract_into($dir, @files);
  return $dir;
}

=method remove_root_dir

  my ($dir, @rel) = $dm->remove_root_dir(@files);

If all the C<@files> are beneath the same root directory
(as is normally the case) this will strip the root directory off of each file
and return a list of the root directory and the stripped files.

If there is no root directory the first element of the list will be C<undef>.

=cut

sub remove_root_dir {
  my ($self, @files) = @_;
  return unless @files;

  # grab the root dir from the first file
  $files[0] =~ m{^([^/]+)/}
    # if not matched quit now
    or return (undef, @files);

  my $dir = $1;
  my @rel;

  # strip $dir from each file
  for (@files) {

    m{^\Q$dir\E/(.+)$}
      # if the match failed they're not all under the same root so just return now
      or return (undef, @files);

    push @rel, $1;
  }

  return ($dir, @rel);

}

=method required_attribute

A single attribute that is required by the class.
Subclasses can define this to make L</new> C<croak> if it isn't present.

=cut

sub required_attribute { return }

=method root

Returns the root directory of the dist (if there is one).

=cut

sub root {
  my ($self) = @_;

  # call list_files instead of find_files so that it caches the result
  $self->list_files
    unless exists $self->{root};

  return $self->{root};
}

=method set_name_and_version

This is a convenience method for setting the name and version
if they haven't already been set.
This is often called by L</determine_name_and_version>.

=cut

sub set_name_and_version {
  my ($self, @values) = @_;
  my @fields = qw( name version );

  foreach my $i ( 0 .. $#fields ){
    $self->{ $fields[$i] } = $values[$i]
      if !exists $self->{ $fields[$i] } && defined $values[$i];
  }
  return;
}

=method version

Returns the version if it could be determined from the dist.

=cut

# version() defined with name()

1;

=head1 SYNOPSIS

  # don't use this, use a subclass

=head1 DESCRIPTION

This is a base class for different dist formats.

The following methods B<must> be defined by subclasses:

=for :list
* L</file_content>
* L</find_files>
