#!/usr/bin/perl
use v5.14;
use Pod::LaTeX;
use Path::Tiny;
my $parser = Pod::LaTeX->new();

# !!! careful with the font
# get the font in your computer: 
#   fc-list :lang=zh
# then  s/FZKai\-Z03/$font_you_want/

#makeatletter is used to display chinese in verbatim
#refer: http://www.cnblogs.com/agateriver/archive/2009/03/24/696153.html
 
my $header = << "__TEX_HEADER__";
\\documentclass[11pt,a4paper]{article}
\\usepackage[top=1.2in,bottom=1.2in,left=1.2in,right=1in]{geometry}
\\usepackage{fontspec}
\\setmainfont{FZKai-Z03}
\\setsansfont{FZKai-Z03}
\\XeTeXlinebreaklocale "zh"
\\XeTeXlinebreakskip = 0pt plus 1pt minus 0.1pt
\\begin{document}
\\makeatletter
\\def\\verbatim\@font\{\\sffamily\\small\} 
\\makeatother
__TEX_HEADER__

$parser->UserPreamble($header);
$parser->MakeIndex(0);

my $pod_dir = path("../CN");
my @pod_files = $pod_dir->children;

# you must intall xelatex to run the program
# I only use it in my linux machine
# have not tested it in others.

foreach my $filename (@pod_files) {
    my $file_name_pod = $filename->stringify;
    my $file_name_tex = $file_name_pod =~ s/pod/tex/r;
    $parser->parse_from_file ($file_name_pod, $file_name_tex);
    system("xelatex $file_name_tex");
    system("rm $file_name_tex");
}

# clean up
system("rm *.log *.aux");

#author: Hao Wu <echowuhao@gmail.com>
#date : 04-01-2012

# it may have bugs in the pdf files and the program itself
# welcome to tell me if you find any, thanks
