BEGIN { require 5.006 } # ‘our’ is used in the tests

use ExtUtils::MakeMaker;

%prq = (
         Hash::Util::FieldHash::Compat      => 0,
         KinoSearch::Highlight::Highlighter => 0,
         List::Util                         => 0,
         Number::Range                      => 0,
         strict                             => 0,
         warnings                           => 0,
# for testing:
	base                                       => 0,
	KinoSearch::Analysis::Tokenizer            => 0,
	KinoSearch::FieldSpec::text                => 0,
	KinoSearch::InvIndex                       => 0,
	KinoSearch::InvIndexer                     => 0,           
	KinoSearch::Searcher                       => 0,
	KinoSearch::Store::RAMFolder               => 0,
	Test::More                                 => 0,
);

eval{require KinoSearch::Highlight::Highlighter}
	&& KinoSearch::Highlight::Highlighter->can('encode')
or $prq{KinoSearch} = 9999, print <<, "\n" ;
This module requires the development version of KinoSearch, revision
3091 or later, which can be obtained from the following URL:
http://www.rectangular.com/svn/kinosearch/trunk


WriteMakefile(
    NAME                => 'KSx::Highlight::Summarizer',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/KSx/Highlight/Summarizer.pm',
    ABSTRACT_FROM       => 'lib/KSx/Highlight/Summarizer.pm',
    PL_FILES            => {},
    PREREQ_PM => \%prq,
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'KSx-Highlight-Summarizer-*' },
);
