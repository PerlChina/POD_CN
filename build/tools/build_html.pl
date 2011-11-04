#!/usr/bin/env perl

use strict;
use warnings;

use Pod::PseudoPod::HTML;
use File::Spec::Functions qw( catfile catdir splitpath );

local *Text::Wrap::wrap;
*Text::Wrap::wrap = sub { $_[2] };

my @pods = get_pods_list();

for my $pod (@pods) {
  my $out_fh = get_output_fh($pod);
  my $parser = Pod::PseudoPod::HTML->new();

  $parser->output_fh($out_fh);
  $parser->add_body_tags(1);
  $parser->add_css_tags(1);
  $parser->complain_stderr(1);
  $parser->parse_file($pod);
}

exit;

sub get_output_fh {
  my $pod     = shift;
  my $name    = ( splitpath $pod )[-1];
  my $htmldir = catdir( qw( build html ) );

  $name       =~ s/\.pod/\.html/;
  $name       = catfile( $htmldir, $name );

  open my $fh, '>:utf8', $name
    or die "Cannot write to '$name': $!\n";

  return $fh;
}

sub get_pods_list {
  my $glob_path = catfile(qw(POD CN *.pod));
  return glob $glob_path;
}

package Pod::PseudoPod::HTML;

no warnings 'redefine';

sub start_Document {
  my ($self) = @_;
  if ($self->{'body_tags'}) {
    my $enc_head = <<'END';
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
END
    $self->{'scratch'} .= "<html>\n$enc_head\n<body>";
    $self->{'scratch'} .= "\n<link rel='stylesheet' href='style.css' type='text/css'>" if $self->{'css_tags'};
    $self->emit('nowrap');
  }
};
