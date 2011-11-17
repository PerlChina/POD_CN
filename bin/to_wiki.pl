#!/usr/bin/perl 
use strict;
use warnings;
use Encode;
use List::Util qw/first/;
use Getopt::Long;
use MediaWiki::Bot;
use File::Spec::Functions qw/catfile splitpath/;
use Pod::Simple::Wiki;
#use Smart::Comments;

my ($username, $password);

GetOptions(
    'username=s' => \$username,
    'password=s' => \$password,
);
die "please specify username and password" unless $username && $password;

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

my $table;
my $perldoc_page = $mw->get_text("perldoc") or die $mw->{error}->{details};
for my $entry (split "\n", $perldoc_page) {
    if ($entry =~ /\[\[(\w+)\]\]/) {
        $table->{$1} = $entry;
    }
}

my @pods   = get_pods_list();
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
    my $parser = Pod::Simple::Wiki->new('mediawiki');
    open my $in, "<", $pod or die $!;
    open my $out, ">:encoding(UTF-8)", \$text or die $!;
    $parser->output_fh($out);
    $parser->parse_file($in);
    close $out;
    close $in;
### update page: $title
### text: $text
### $pod: $pod
    $mw->edit(
        {   page    => "$title",
            text    => decode("utf8", $text),
            summary => "update wiki at "
              . scalar localtime(time)
              . "by $username",
            bot => 1,
            assertion => 'bot',
        }
    ) or die $mw->{error}->{details};

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
          . "by $username",
    }
) or die $mw->{error}->{details};

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
    $return->{translator} = 'github';
    return $return;
}
