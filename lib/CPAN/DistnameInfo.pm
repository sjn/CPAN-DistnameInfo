
package CPAN::DistnameInfo;

$VERSION = "0.05";
use strict;

sub distname_info {
  my $file = shift or return;

  my ($dist, $version) = $file =~ /^
    ((?:[-+.]*(?:[A-Za-z0-9]+|(?<=\D)_|_(?=\D))*
     (?:
	[A-Za-z](?=[^A-Za-z]|$)
	|
	\d(?=-)
     )(?<![._-][vV])
    )+)(.*)
  $/xs or return ($file,undef,undef);

  if ($version =~ /^(-[Vv].*)-(\d.*)/) {
   
    # Catch names like Unicode-Collate-Standard-V3_1_1-0.1
    # where the V3_1_1 is part of the distname
    $dist .= $1;
    $version = $2;
  }

  $version = $1
    if !length $version and $dist =~ s/-(\d+\w)$//;

  $version = $1 . $version
    if $version =~ /^\d+$/ and $dist =~ s/-(\w+)$//;

  if ($version =~ /\d\.\d/) {
    $version =~ s/^[-_.]+//;
  }
  else {
    $version =~ s/^[-_]+//;
  }

  my $dev;
  if (length $version) {
    if ($file =~ /^perl-?\d+\.(\d+)(?:\D(\d+))?(-(?:TRIAL|RC)\d+)?$/) {
      $dev = 1 if (($1 > 6 and $1 & 1) or ($2 and $2 >= 50)) or $3;
    }
    elsif ($version =~ /\d\D\d+_\d/) {
      $dev = 1;
    }
  }
  else {
    $version = undef;
  }

  ($dist, $version, $dev);
}

sub new {
  my $class = shift;
  my $distfile = shift;

  $distfile =~ s,//+,/,g;

  my %info = ( pathname => $distfile );

  ($info{filename} = $distfile) =~ s,^(((.*?/)?authors/)?id/)?([A-Z])/(\4[A-Z])/(\5[-A-Z]*)/,,
    and $info{cpanid} = $6;

  if ($distfile =~ m,([^/]+)\.(tar\.g?z|zip|tgz)$,i) { # support more ?
    $info{distvname} = $1;
    $info{extension} = $2;
  }

  @info{qw(dist version beta)} = distname_info($info{distvname});
  $info{maturity} = delete $info{beta} ? 'developer' : 'released';

  return bless \%info, $class;
}

sub dist      { shift->{dist} }
sub version   { shift->{version} }
sub maturity  { shift->{maturity} }
sub filename  { shift->{filename} }
sub cpanid    { shift->{cpanid} }
sub distvname { shift->{distvname} }
sub extension { shift->{extension} }
sub pathname  { shift->{pathname} }

sub properties { %{ $_[0] } }

1;

__END__

=head1 NAME

CPAN::DistnameInfo - Extract distribution name and version from a distribution filename

=head1 SYNOPSIS

  my $pathname = "authors/id/G/GB/GBARR/CPAN-DistnameInfo-0.02.tar.gz";

  my $d = CPAN::DistnameInfo->new($pathname);

  my $dist      = $d->dist;      # "CPAN-DistnameInfo"
  my $version   = $d->version;   # "0.02"
  my $maturity  = $d->maturity;  # "released"
  my $filename  = $d->filename;  # "CPAN-DistnameInfo-0.02.tar.gz"
  my $cpanid    = $d->cpanid;    # "GBARR"
  my $distvname = $d->distvname; # "CPAN-DistnameInfo-0.02"
  my $extension = $d->extension; # "tar.gz"
  my $pathname  = $d->pathname;  # "authors/id/G/GB/GBARR/..."

  my %prop = $d->properties;

=head1 DESCRIPTION

Many online services that are centered around CPAN attempt to
associate multiple uploads by extracting a distribution name from
the filename of the upload. For most distributions this is easy as
they have used ExtUtils::MakeMaker or Module::Build to create the
distribution, which results in a uniform name. But sadly not all
uploads are created in this way.

C<CPAN::DistnameInfo> uses heuristics that have been learnt by
L<http://search.cpan.org/> to extract the distribution name and
version from filenames and also report if the version is to be
treated as a developer release

The constructor takes a single pathname, returning an object with the following methods

=over

=item cpanid

If the path given looked like a CPAN authors directory path, then this will be the
the CPAN id of the author.

=item dist

The name of the distribution

=item distvname

The file name with any suffix and leading directory names removed

=item filename

If the path given looked like a CPAN authors directory path, then this will be the
path to the file relative to the detected CPAN author directory. Otherwise it is the path
that was passed in.

=item maturity

The maturity of the distribution. This will be either C<released> or C<developer>

=item extension

The extension of the distribution, often used to denote the archive type (e.g. 'tar.gz')

=item pathname

The pathname that was passed to the constructor when creating the object.

=item properties

This will return a list of key-value pairs, suitable for assigning to a hash,
for the known properties.

=item version

The extracted version

=back

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT 

Copyright (c) 2003 Graham Barr. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

