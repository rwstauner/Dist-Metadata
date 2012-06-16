package Dist::Metadata::Test::LikePause;

# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = '0.1';

# This package should be excluded if like_pause => 1
package ExtraPackage;

our $VERSION = '0.2';
