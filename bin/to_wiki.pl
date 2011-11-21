#!/usr/bin/perl 
use strict;
use warnings;
use Encode;
use List::Util qw/first/;
use Getopt::Std;
use MediaWiki::Bot;
use File::Spec::Functions qw/catfile splitpath/;
use Pod::Simple::Wiki;

#use Smart::Comments;

our ($opt_u, $opt_p, $opt_U);

getopt("upU");

die "please specify username and password" unless $opt_u && $opt_p;

my $mw = MediaWiki::Bot->new(
    {   host => 'wiki.perlchina.org',
        path => '/',
    }
);

$mw->login(
    {   username => $opt_u,
        password => $opt_p,
    }
) or die $mw->{error}->{details};

if (!$opt_U) {
    my @pods = get_pods_list();
    for my $pod (@pods) {
        my $title = (splitpath($pod))[-1];
        $title =~ s/.pod$//i;
        update_page($mw, $title, \&pod_to_wiki);
    }
    update_perldoc_page($mw);
} else {
    my @titles = split ',', $opt_U;
    for (@titles) {
        if ($_ eq 'perldoc') {
            update_perldoc_page($mw);
            next;
        }
        update_page($mw, $_, \&pod_to_wiki);
    }
}

exit;

sub get_pods_list {
    my $glob_path = catfile(qw(POD CN *.pod));
    return glob $glob_path;
}

sub extra_pod_info {
    open my $fh, "<", shift or die $!;
    my $return;
    my $content = decode(
        'utf8',
        do { local $/; <$fh> }
    );
    if ($content =~ m/\n=head1\s+NAME\s*\n+\s+(.+)\s*?\n/mi) {
        $return->{name} = $1;

        ## 有时候有回车符
        $return->{name} =~ s/\r$//;
    }

    #if($content =~ m/\n=head1\s+TRANSLATORS\s*?\n+(\w+)\n/i){
    #   my $return->{translator} = $1;
    #}
    $return->{translator} = 'bot@Github';
    return $return;
}

sub update_page {
    my ($mw, $title, $get_content) = @_;
    my $new_page = $get_content->($title);
    $mw->edit(
        {   page    => "$title",
            text    => decode('utf8', $new_page),
            summary => "update wiki at "
              . scalar localtime(time)
              . "by ",
        }
    ) or die $mw->{error}->{details};
}

sub pod_to_wiki {
    my $page = shift;
    my $pod = catfile("POD", "CN", "$page.pod");

    my $text;
    my $parser = Pod::Simple::Wiki->new('mediawiki');
    open my $in, "<", $pod or die $!;
    open my $out, ">:encoding(UTF-8)", \$text or die $!;
    $parser->output_fh($out);
    $parser->parse_file($in);
    close $out;
    close $in;
    return $text;
}

sub update_perldoc_page {
    my $mw = shift;
    my $table;
    my $perldoc_page = $mw->get_text("perldoc")
      or die $mw->{error}->{details};
    for my $entry (split "\n", $perldoc_page) {
        if ($entry =~ /\[\[(\w+)\]\]/) {
            $table->{$1} = $entry;
        }
    }
    my @pods = get_pods_list();
    foreach my $pod (@pods) {
        my $info = extra_pod_info($pod);

        my $page = (splitpath($pod))[-1];
        $page =~ s/.pod$//i;
        if ($info->{name}) {
            $info->{name} =~ s/$page/*\[\[$page\]\]/;
            $table->{$page} = $info->{name};
        }
    }

    my $new_page;
    my $done = 0;
    for my $entry (split "\n", $perldoc_page) {
        if ($entry =~ /\[\[(\w+)\]\]/) {
            $done && next;
            ## get everything to doc;
            for (sort keys %$table) {
                $new_page .= $table->{$_} . "\n";
            }
            $done = 1;
        } else {
            $new_page .= "$entry\n";
        }
    }

### new_page: $new_page

    $mw->edit(
        {   page    => "perldoc",
            text    => $new_page,
            summary => "update wiki at "
              . scalar localtime(time)
              . " by $mw->{username}",
        }
    ) or die $mw->{error}->{details};

}

sub help {
    print <<"EOF";
    $0 -u username -p password -U perlootut,perlxstut,perldoc
EOF
}
