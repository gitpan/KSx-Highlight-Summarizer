BEGIN { require 5.006 } # ‘our’ is used in the tests

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'KSx::Highlight::Summarizer',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/KSx/Highlight/Summarizer.pm',
    ABSTRACT_FROM       => 'lib/KSx/Highlight/Summarizer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         Hash::Util::FieldHash::Compat      => 0,
         KinoSearch::Highlight::Highlighter => 0,
         List::Util                         => 0,
         Number::Range                      => 0,
         strict                             => 0,
         warnings                           => 0,
# for testing:
	base                                       => 0,
	KinoSearch                                 =>  .2, # not used
	KinoSearch::Analysis::Tokenizer            => 0,   # directly, but
	KinoSearch::FieldSpec::text                => 0,   # it’s the only
	KinoSearch::Highlight::Encoder             => 0,   # module in the
	KinoSearch::Highlight::SimpleHTMLFormatter => 0,   # distribution
	KinoSearch::InvIndex                       => 0,   # that has  the
	KinoSearch::InvIndexer                     => 0,   # version number           
	KinoSearch::Searcher                       => 0,
	KinoSearch::Store::RAMFolder               => 0,
	Test::More                                 => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'KSx-Highlight-Summarizer-*' },
);
