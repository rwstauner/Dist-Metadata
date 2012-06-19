package Dist::Metadata::Test::LikePause;

# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = '0.1';

# This should be excluded unless "include_inner_packages" is true
package ExtraPackage;

our $VERSION = '0.2';
