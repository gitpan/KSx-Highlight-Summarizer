#!/usr/bin/perl -w

# Half of this test script was stolen from KinoSearch’s Highlighter tests
# (with the appropriate modifications).

use strict;
use warnings;

use Test::More tests =>
+	1 # load
+	9 # stolen from KinoSearch::Highlighter
+	5 # KSx:H:S-specific features
;

use_ok 'KSx::Highlight::Summarizer'; # test 1


package MySchema::alt;
use base qw( KinoSearch::FieldSpec::text );
sub boost {0.1}

package MySchema;
use base qw( KinoSearch::Schema );
use KinoSearch::Analysis::Tokenizer;

our %fields = (
    content => 'text',
    alt     => 'MySchema::alt',
);

sub analyzer { KinoSearch::Analysis::Tokenizer->new }

package main;

# ------ KinoSearch::Highlight::Highlighter’s tests (9 of them) ------- #

use KinoSearch::Searcher;
use KinoSearch::Highlight::Highlighter;
use KinoSearch::InvIndexer;
use KinoSearch::InvIndex;
use KinoSearch::Store::RAMFolder;

my $phi         = "\x{03a6}";
my $encoded_phi = "&phi;";

my $string = '1 2 3 4 5 ' x 20;    # 200 characters
$string .= "$phi a b c d x y z h i j k ";
$string .= '6 7 8 9 0 ' x 20;
my $with_quotes = '"I see," said the blind man.';
my $invindex    = KinoSearch::InvIndex->clobber(
    folder => KinoSearch::Store::RAMFolder->new,
    schema => MySchema->new,
);

my $invindexer = KinoSearch::InvIndexer->new( invindex => $invindex, );
$invindexer->add_doc( { content => $_ } ) for ( $string, $with_quotes );
$invindexer->add_doc(
    {   content => "x but not why or 2ee",
        alt     => $string . " and extra stuff so it scores lower",
    }
);
$invindexer->add_doc( { content => 'haecceity: you don’t know what that'
	. ' word means, do you? ' . '3 ' x 1000
	. 'Look, here it is again: haecceity'
} );
$invindexer->add_doc( { content => "blah blah blah " . 'rhubarb ' x 40
	. "\014 page 2 \014 "
	. "σελίδα 3 \014 " . '42 ' x 1000 . "Seite 4"
} );
$invindexer->finish;

my $searcher = KinoSearch::Searcher->new( invindex => $invindex, );

my $q = qq|"x y z" AND $phi|;
my $hits = $searcher->search( query => $q );
my $hit = $hits->fetch_hit;
my $hl = KSx::Highlight::Summarizer->new(
    searchable => $searcher,
    query      => $q,
    field      => 'content',
);
my $excerpt = $hl->create_excerpt( $hit );
like( $excerpt,
    qr/$encoded_phi.*?z/i, "excerpt contains all relevant terms" );
like(
    $excerpt,
    qr#<strong>x y z</strong>#,
    "highlighter tagged the phrase"
);
like(
    $excerpt,
    qr#<strong>$encoded_phi</strong>#i,
    "highlighter tagged the single term"
);

like( $hl->create_excerpt( $hits->fetch_hit() ),
    qr/x/,
    "excerpt field with partial hit doesn't cause highlighter freakout" );

$hits = $searcher->search( query => $q = 'x "x y z" AND b' );
$hl = KSx::Highlight::Summarizer->new(
    searchable => $searcher,
    query      => $q,
    field      => 'content',
);
like( $hl->create_excerpt( $hits->fetch_hit() ),
    qr/x y z/,
    "query with same word in both phrase and term doesn't cause freakout" );

$hits = $searcher->search( query => $q = 'blind' );
like(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $q,
        field      => 'content',
    )->create_excerpt( $hits->fetch_hit() ),
    qr/quot/, "HTML entity encoded properly" );

$hits = $searcher->search( query => $q = 'why' );
unlike(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $q,
        field      => 'content',
    )->create_excerpt( $hits->fetch_hit() ),
    qr/\.\.\./, "no ellipsis for short excerpt" );

my $term_query = KinoSearch::Search::TermQuery->new(
    term => KinoSearch::Index::Term->new( content => 'x' ) );
$hits = $searcher->search( query => $term_query );
$hit = $hits->fetch_hit();
like(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $term_query,
        field      => 'content',
    )->create_excerpt( $hit ),
    qr/strong/, "specify field highlights correct field..." );
unlike(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $term_query,
        field      => 'alt',
    )->create_excerpt( $hit ),
    qr/strong/, "... but not another field"
);


# ---- KSx::Highlight::Summarizer-specific tests (5 of them) ---- #

# 1 test for p(re|ost)_tag and encoder in the constructor

$q = qq|"x y z" AND $phi|;
$hits = $searcher->search( query => $q );
$hit = $hits->fetch_hit;
$hl = KSx::Highlight::Summarizer->new(
    searchable  => $searcher,
    query       => $q,
    field       => 'content',
    pre_tag => ' Oh look! -->',
    post_tag => '<-- ',
    encoder   => sub { for(my $x = shift) {
		s/(\S)/ord $1/ge; return $_
	}},
);
$excerpt = $hl->create_excerpt( $hit );
like(
    $excerpt,
    qr# Oh look! -->934<-- #i,
    "encoder and p(re|ost)_tag in the constructor"
);


# 3 tests for page-break handling

$hits = $searcher->search(query => 'page');
$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'page',
	field      => 'content',
;
like($hl->create_excerpt($hit = fetch_hit $hits), qr/&#12;/,
	'FFs are left alone without a page_h');
$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'page',
	field      => 'content',
	page_handler => sub {
		my ($hitdoc, $page_no) = @_;
		"This is from page $page_no:" . ' ' x ($page_no == 1);
	}
;
like($hl->create_excerpt($hit),
	qr/This is from page 2: <strong>page<\/strong> 2/,
	'page breaks within a few characters from the highlit word');
	# yes, I know highlit isn’t a real word
$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'Seite', # this is the only difference between this
	field      => 'content',  # highlighter and the previous one
	page_handler => sub {
		my ($hitdoc, $page_no) = @_;
		"This is from page $page_no: ";
	}
;
like($hl->create_excerpt($hit), qr/This is from page 4:\s+\.\.\. .*Seite/,
	'Page marker followed by ellipsis');


# 1 test for custom ellipsis marks and for summaries

$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'blah Seite',
	field      => 'content', 
	summary_length => 400,
	ellipsis => ' yoda yoda yoda ',
;
like ($hl->create_excerpt($hit), qr/blah.*? yoda yoda yoda .*?Seite/,
	'summaries and custom ellipsis marks');

