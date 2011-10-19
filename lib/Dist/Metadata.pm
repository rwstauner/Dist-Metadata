# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Metadata;
# ABSTRACT: Information about a perl module distribution

use Carp qw(croak carp);
use CPAN::Meta 2.1 ();
use List::Util qw(first);    # core in perl v5.7.3

# something that is obviously not a real value
use constant UNKNOWN => '- unknown -';

=method new

  Dist::Metadata->new(file => $path);

A dist can be represented by
a tar file,
a directory,
or a data structure.

The format will be determined by the presence of the following options
(checked in this order):

=for :list
* C<struct> - hash of data to build a mock dist; See L<Dist::Metadata::Struct>.
* C<dir> - path to the root directory of a dist
* C<file> - the path to a F<.tar.gz> file

You can also slyly pass in your own object as a C<dist> parameter
in which case this module will just use that.
This can be useful if you need to use your own subclass
(perhaps while developing a new format).

Other options that can be specified:

=begin :list

* C<name> - dist name

* C<version> - dist version

=item *

C<determine_packages> - boolean to indicate whether dist should be searched
for packages if no META file is found.  Defaults to true.

=end :list

=cut

sub new {
  my $class = shift;
  my $self  = {
    determine_packages => 1,
    @_ == 1 ? %{ $_[0] } : @_
  };

  my @formats = qw( dist file dir struct );
  croak(qq[A dist must be specified (one of ] .
      join(', ', map { "'$_'" } @formats) . ')')
    unless first { $self->{$_} } @formats;

  bless $self, $class;
}

=method dist

Returns the dist object (subclass of L<Dist::Metadata::Dist>).

=cut

sub dist {
  my ($self) = @_;
  return $self->{dist} ||= do {
    my $dist;
    if( my $struct = $self->{struct} ){
      require Dist::Metadata::Struct;
      $dist = Dist::Metadata::Struct->new(%$struct);
    }
    elsif( my $dir = $self->{dir} ){
      require Dist::Metadata::Dir;
      $dist = Dist::Metadata::Dir->new(dir => $dir);
    }
    elsif ( my $file = $self->{file} ){
      require Dist::Metadata::Archive;
      $dist = Dist::Metadata::Archive->new(file => $file);
    }
    else {
      # new() checks for one and dies without so we shouldn't get here
      croak q[No dist format parameters found!];
    }
    $dist; # return
  };
}

=method default_metadata

Returns a hashref of default values
used to initialize a L<CPAN::Meta> object
when a META file is not found.
Called from L</determine_metadata>.

=cut

sub default_metadata {
  my ($self) = @_;

  return {
    # required
    abstract       => UNKNOWN,
    author         => [],
    dynamic_config => 0,
    generated_by   => ( ref($self) || $self ) . ' version ' . $self->VERSION,
    license        => ['unknown'], # this 'unknown' comes from CPAN::Meta::Spec
    'meta-spec'    => {
      version => '2',
      url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    name           => UNKNOWN,

    # strictly speaking, release_status is also required but
    # CPAN::Meta will figure it out based on the version number.  if
    # we were to set it explicitly, then we would first need to
    # examine the version number for '_' or 'TRIAL' or 'RC' etc.
    version        => 0,

    # optional
    no_index => {
      # ignore test and build directories by default
      directory => [qw( inc t xt )],
    },
    # provides => { package => { file => $file, version => $version } }
  };
}

=method determine_metadata

Examine the dist and try to determine metadata.
Returns a hashref which can be passed to L<CPAN::Meta/new>.
This is used when the dist does not contain a META file.

=cut

sub determine_metadata {
  my ($self) = @_;

  my $dist = $self->dist;
  my $meta = $self->default_metadata;

  # get name and version from dist if dist was able to parse them
  foreach my $att (qw(name version)) {
    my $val = $dist->$att;
    # if the dist could determine it that's better than the default
    # but undef won't validate.  value in $self will still override.
    $meta->{$att} = $val
      if defined $val;
  }

  # any passed in values should take priority
  foreach my $field ( keys %$meta ){
    $meta->{$field} = $self->{$field}
      if exists $self->{$field};
  }

  return $meta;
}

=method determine_packages

  my $provides = $dm->determine_packages($meta);

Attempt to determine packages provided by the dist.
This is used when the META file does not include a C<provides>
section and C<determine_packages> is not set to false in the constructor.


If a L<CPAN::Meta> object is not provided a default one will be used.
Files contained in the dist and packages found therein will be checked against
the meta object's C<no_index> attribute
(see L<CPAN::Meta/should_index_file>
and  L<CPAN::Meta/should_index_package>).
By default this ignores any files found in
F<inc/>,
F<t/>,
or F<xt/>
directories.

=cut

sub determine_packages {
  # meta must be passed to avoid infinite loop
  my ( $self, $meta ) = @_;
  # if not passed in, use defaults (we just want the 'no_index' property)
  $meta ||= $self->meta_from_struct( $self->determine_metadata );

  # should_index_file() expects unix paths
  my @files = grep {
    $meta->should_index_file(
      $self->dist->path_classify_file($_)->as_foreign('Unix')->stringify
    );
  }
    $self->dist->perl_files;

  # TODO: should we limit packages to lib/ if it exists?
  # my @lib = grep { m#^lib/# } @files; @files = @lib if @lib;

  return {} if not @files;

  my $packages = $self->dist->determine_packages(@files);

  # remove any packages that should not be indexed
  foreach my $pack ( keys %$packages ) {
    delete $packages->{$pack}
      if !$meta->should_index_package($pack);
  }

  return $packages;
}

=method load_meta

Loads the metadata from the L</dist>.

=cut

sub load_meta {
  my ($self) = @_;

  my $dist  = $self->dist;
  my @files = $dist->list_files;
  my ( $meta, $metafile );
  my $default_meta = $self->determine_metadata;

  # prefer json file (spec v2)
  if ( $metafile = first { m#^META\.json$# } @files ) {
    $meta = CPAN::Meta->load_json_string( $dist->file_content($metafile) );
  }
  # fall back to yaml file (spec v1)
  elsif ( $metafile = first { m#^META\.ya?ml$# } @files ) {
    $meta = CPAN::Meta->load_yaml_string( $dist->file_content($metafile) );
  }
  # no META file found in dist
  else {
    $meta = $self->meta_from_struct( $default_meta );
  }

  {
    # always inlude (never index) the default no_index dirs
    my $dir = ($meta->{no_index} ||= {})->{directory} ||= [];
    my %seen = map { ($_ => 1) } @$dir;
    unshift @$dir,
      grep { !$seen{$_}++ }
          @{ $default_meta->{no_index}->{directory} };
  }

  # Something has to be indexed, so if META has no (or empty) 'provides'
  # attempt to determine packages unless specifically configured not to
  if ( !keys %{ $meta->provides || {} } && $self->{determine_packages} ) {
    # respect api/encapsulation
    my $struct = $meta->as_struct;
    $struct->{provides} = $self->determine_packages($meta);
    $meta = $self->meta_from_struct($struct);
  }

  return $meta;
}

=method meta

Returns the L<CPAN::Meta> instance in use.

=cut

sub meta {
  my ($self) = @_;
  return $self->{meta} ||= $self->load_meta;
}

=method meta_from_struct

  $meta = $dm->meta_from_struct(\%struct);

Passes the the provided C<\%struct> to L<CPAN::Meta/create>
and returns the result.

=cut

sub meta_from_struct {
  my ($self, $struct) = @_;
  return CPAN::Meta->create( $struct, { lazy_validation => 1 } );
}

=method package_versions

  $pv = $dm->package_versions();
  # { 'Package::Name' => '1.0', 'Module::2' => '2.1' }

Returns a simplified version of C<provides>:
a hashref with package names as keys and versions as values.

This can also be called as a class method
which will operate on a passed in hashref.

  $pv = Dist::Metadata->package_versions(\%provides);

=cut

sub package_versions {
  my ($self) = shift;
  my $provides = @_ ? shift : $self->provides; # || {}
  return {
    map { ($_ => $provides->{$_}{version}) } keys %$provides
  };
}

=head1 INHERITED METHODS

The following methods are available on this object
and simply call the corresponding method on the L<CPAN::Meta> object.

=for :list
* X<name> name
* X<provides> provides
* X<version> version

=cut

{
  no strict 'refs'; ## no critic (NoStrict)
  foreach my $method ( qw(
    name
    provides
    version
  ) ){
    *$method = sub { $_[0]->meta->$method };
  }
}

1;

=for Pod::Coverage name version provides

=for test_synopsis
my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);

  my $description = sprintf "Dist %s (%s)", $dist->name, $dist->version;

  my $provides = $dist->package_versions;
  while( my ($package, $version) = each %$provides ){
    print "$description includes $package $version\n";
  }

=head1 DESCRIPTION

This module provides an easy interface for getting various metadata
about a Perl module distribution.

It takes care of the common logic of:

=for :list
* reading a tar file (L<Archive::Tar>)
* finding and reading the correct META file if the distribution contains one (L<CPAN::Meta>)
* and determining some of the metadata if there is no META file (L<Module::Metadata>, L<CPAN::DistnameInfo>)

This is mostly a wrapper around L<CPAN::Meta> providing an easy interface
to find and load the meta file from a F<tar.gz> file.
A dist can also be represented by a directory or merely a structure of data.

If the dist does not contain a meta file
the module will attempt to determine some of that data from the dist.

B<NOTE>: This interface is still being defined.
Please submit any suggestions or concerns.

=head1 TODO

=for :list
* More tests
* C<trust_meta> option (to allow setting it to false)
* Guess main module from dist name if no packages can be found
* Determine abstract?
* Add change log info (L<CPAN::Changes>)?
* Subclass as C<CPAN::Dist::Metadata> just so that it has C<CPAN> in the name?
* Use L<File::Find::Rule::Perl>?

=head1 SEE ALSO

=head2 Dependencies

=for :list
* L<CPAN::Meta>
* L<Module::Metadata>
* L<CPAN::DistnameInfo>

=head2 Related Modules

=for :list
* L<MyCPAN::Indexer>
* L<CPAN::ParseDistribution>

=cut
