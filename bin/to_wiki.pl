#!/usr/bin/perl 
use strict;
use warnings;
use Encode;
use List::Util qw/first/;
use Getopt::Long;
use MediaWiki::Bot;
use File::Spec::Functions qw/catfile splitpath/;
use Pod::Simple::Wiki;
use Data::Printer;
#use Devel::Peek;

my ($username, $password);
my $mw = MediaWiki::Bot->new(
    {   host => 'wiki.perlchina.org',
        path => '/',
    }
);

$mw->login(
    {   username => $username,
        password => $password,
    }
) or die $mw->{error}->{details};

my @pods = get_pods_list();
my $parser = Pod::Simple::Wiki->new('mediawiki');
my $table;
my $perldoc_page = $mw->get_text("perldoc") or die $mw->{error}->{details};
for my $entry (split "\n", $perldoc_page) {
    if ($entry =~ /\[\[(\w+)\]\]/) {
        $table->{$1} = $entry;
    }
}
for my $pod (@pods) {
    my $title = (splitpath($pod))[-1];
    $title =~ s/.pod$//i;
    my $info = extra_pod_info($pod);
    if ($info->{name}) {
        $info->{name} =~ s/$title/*\[\[$title\]\]/;
        $table->{$title} =
          $info->{name} . decode('utf8', "[认领人: $info->{translator}]");
    }

    my $text;
    open my $in, "<", $pod or die $!;
    open my $out, ">:encoding(UTF-8)", \$text or die $!;
    $parser->output_fh($out);
    $parser->parse_file($in);
    close $out;
    close $in;
# $mw->edit(
#        {   page    => "$title",
#            text    => decode("utf8", $text),
#            summary => "update wiki at " . scalar localtime(time),
#        }
#    ) or die $mw->{error}->{details};
    
}
exit;

sub get_pods_list {
    my $glob_path = catfile(qw(POD CN *.pod));
    return glob $glob_path;
}

sub extra_pod_info($) {
    open my $fh, "<", shift or die $!;
    my $return;
    my $content = decode(
        'utf8',
        do { local $/; <$fh> }
    );
    if ($content =~ m/\n=head1\s+NAME\s*\n+\s+(.+)\s*?\n/mi) {
        $return->{name} = $1;

        ### 有时候有回车符
        $return->{name} =~ s/\r$//;
    }

    #if($content =~ m/\n=head1\s+TRANSLATORS\s*?\n+(\w+)\n/i){
    #   my $return->{translator} = $1;
    #}
    $return->{translator} = 'github';
    return $return;
}
