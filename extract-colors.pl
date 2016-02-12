#!/usr/local/bin/perl -w

package MT::Tool::AssetColorExtractor;

use strict;
use warnings;
use lib qw( lib extlib plugins/AssetColorExtractor/lib );
use base qw( MT::Tool );
use MT;
use AssetColorExtractor::Plugin;
use Data::Dumper;
use MT::Asset;

sub main {
    my $app = MT->instance;

    my $blog_id = $ARGV[0];

    my $terms = { class => ['image', 'photo'], };
    if ($blog_id) {
        $terms->{blog_id} = $blog_id;
    }

    my $iter = $app->model('asset')->load_iter(
        $terms,
        {
            sort      => 'blog_id',
            direction => 'ascend',
        }
    );

    while ( my $asset = $iter->() ) {
        ($asset) = AssetColorExtractor::Plugin::extract_color( $asset );
        if ($asset) {
            print '* Extracted colors for "' . $asset->file_name . '" from blog ID '
                . $asset->blog_id . ': ' . $asset->extracted_colors . "\n";
        }
    }
}

__PACKAGE__->main();
