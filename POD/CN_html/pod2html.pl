#!/usr/bin/perl
use v5.14;
use TOBYINK::Pod::HTML;
use Path::Tiny;

#copied from the cpan document

my $pod2html = "TOBYINK::Pod::HTML"->new(
   pretty             => 1,       # nicely indented HTML

##TODO: code_highlighting not work at the moment 

#  code_highlighting  => 1,       # use PPI::HTML
 #  code_line_numbers  => 1,
 #  code_styles        => {        # some CSS
 #     comment   => 'color:green',
 #     keyword   => 'font-weight:bold',
 #   }
);
 
my $pod_dir = path("../CN");
my @pod_files = $pod_dir->children;



#rewrite the metacpan link to internal link

sub rewrite_metacpan_link {
    my $html_string = shift;
    $html_string =~s!https://metacpan\.org/module/(\w+)!$1\.html!gr;
}

foreach my $filename (@pod_files) {
    my $file_name_pod = $filename->stringify;
    my $file_name_html = $file_name_pod =~ s/pod/html/r;
    my $pod_html =  $pod2html->file_to_xhtml($file_name_pod);
    $pod_html = rewrite_metacpan_link($pod_html);
    path(path($file_name_html)->basename)->spew($pod_html);
}


