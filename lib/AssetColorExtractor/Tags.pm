package AssetColorExtractor::Tags;

use strict;
use warnings;

# AssetExtractedColors block tag
sub block_extracted_colors {
    my ( $ctx, $args, $cond ) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $asset   = $ctx->stash('asset');
    
    # Verify that this is an image asset.
    return if ($asset->class !~ m/(image|photo)/);
    
    my @extracted_colors = split(',', $asset->extracted_colors);

    # No colors found? Extract them now. This isn't a user-configurable setting
    # so whatever colors we get are good. And, if they are being published then
    # they are obviously needed.
    if (!@extracted_colors) {
        require AssetColorExtractor::Plugin;
        $asset = AssetColorExtractor::Plugin::extract_color( $asset );
        @extracted_colors = split(',', $asset->extracted_colors);
    }

    my $res  = '';
    my $i    = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};

    foreach my $extracted_color (@extracted_colors) {
        local $vars->{__first__}   = !$i;
        local $vars->{__last__}    = !defined $extracted_colors[$i+1];
        local $vars->{__odd__}     = ($i % 2) == 0; # 0-based $i
        local $vars->{__even__}    = ($i % 2) == 1;
        local $vars->{__counter__} = $i+1;

        # Save all of the color data to the stash for the template tags.
        local $ctx->{__stash}{asset_extracted_color} = $extracted_color;

        defined(my $out = $builder->build($ctx, $tokens, $cond))
            or return $ctx->error( $builder->errstr );
        $res .= $out;

        $i++;
    }

    return $res;
}

# AssetExtractedColor function tag
# Optional arguments include `index` and `_default`.
sub function_extracted_color {
    my ( $ctx, $args, $cond ) = @_;

    # In the AssetExtractedColors block?
    my $extracted_color = $ctx->stash('asset_extracted_color');

    # If we're not in the AssetExtractedColors block, just return the first
    # color in the array for the template.
    if (!defined $extracted_color) {
        my $asset = $ctx->stash('asset');

        # Verify that this is an image asset.
        return if ($asset->class !~ m/(image|photo)/);

        my @extracted_colors = split(',', $asset->extracted_colors);

        # No colors found? Extract them now. This isn't a user-configurable
        # setting so whatever colors we get are good. And, if they are being
        # published then they are obviously needed.
        if (!@extracted_colors && $args->{generate} == 1) {
            require AssetColorExtractor::Plugin;
            $asset = AssetColorExtractor::Plugin::extract_color( $asset );
            @extracted_colors = split(',', $asset->extracted_colors);
        }

        # Grab the requested position in the array for the template, as a way
        # to get the second color, for example.
        my $i = $args->{'index'};
        $i--; # Index starts at 0, so subtract 1 from whatever was requested.

        # Try to grab the requested color index. If unavailable use the
        # previous one in the array. Keep trying until we get something, then
        # fall back to the default.
        while ( !defined $extracted_color ) {
            $extracted_color = $extracted_colors[$i];

            # Is there some scenario in which an extracted color wouldn't be
            # found? Colors can be extracted above so I'd expect something to
            # always be available, but...
            if (!defined $extracted_color && $i == 0 ) {
                $extracted_color = $args->{'_default'}
                    || $args->{'default'} # In case they forget the leading `_`.
                    || '#000000';
            }

            $i--;
        }
    }

    return $extracted_color;
}

1;

__END__
