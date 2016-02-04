package AssetColorExtractor::Plugin;

use strict;
use warnings;

use Image::Magick;

# Extract colors on file upload. This is for both the CMS and API callback
# methods.
sub upload_file_callback {
    my $cb = shift;
    my (%params) = @_;
    my $asset = $params{'Asset'};
    extract_color( $asset );
}

# Do the actual color extraction. An image asset should have been provided.
# Reduce the color depth to even out the colors, then extract them based on the
# image histogram. Save as asset meta.
sub extract_color {
    my ($asset) = @_;
    my $blog_id = $asset->blog_id;

    # Verify that this is an image asset.
    return if ($asset->class !~ m/(image|photo)/);

    my $image = Image::Magick->new;
    $image->Read( filename => $asset->file_path );

    if (! $image) {
        MT->log({
            class    => 'Asset Color Extractor',
            category => 'extract_color',
            level    => MT->model('log')->ERROR(),
            blog_id  => $blog_id,
            message  => 'The Asset Color Extractor plugin could not read the'
                . ' specified file at ' . $asset->file_path . '.',
        });
        return 1;
    }

    # Reduce the number of colors. Resizing simplifies and better places
    # emphasis on color differences, and Segment helps to homogenize colors.
    # Resize first so that a smaller image is used, which speeds up the process
    # substantially.
    if ( $asset->image_width > 100) {
        $image->Resize( width => 100 );
    }
    $image->Segment( colorspace => 'RGB' );

    # Histogram returns data as a single list, but the list is actually groups
    # of 5 elements (red value, green value, blue value, alpha transparency,
    # and count of occurrences). Turn it into a list of useful hashes.
    my @hist_data = $image->Histogram;
    my @hist_entries;
    while (@hist_data) {
        my ($r, $g, $b, $a, $count) = splice @hist_data, 0, 5;

        my $hex_color = _build_hex_color( $r, $g, $b );

        push @hist_entries, {
            hex   => $hex_color,
            count => $count,
        };
    }
    # Sort the colors in decreasing order
    @hist_entries = sort { $b->{count} <=> $a->{count} } @hist_entries;

    # How many colors should be extracted?
    my $plugin        = MT->component('assetcolorextractor');
    my $num_of_colors = $plugin->get_config_value(
        'number_of_colors',
        'blog:' . $blog_id
    );

    my @saved_colors;
    for ( my $i = 0; $i < $num_of_colors; $i++ ) {
        push @saved_colors, $hist_entries[$i]->{hex};
    }

    $asset->extracted_colors( join(',', @saved_colors) );
    $asset->save or die $asset->errstr;

    return $asset;
}

# Convert decimal RGB values (0..65536) to hex values (00..FF) to build
# a hex color value useful for the web.
sub _build_hex_color {
    my (@color_array) = @_;
    my $hex_color = '#';

    foreach my $color ( @color_array ) {
        $color = sprintf('%05d', $color);
        my $hex = sprintf('%02X', $color / 256);

        if ($hex eq '0') {
            $hex = '00';
        }

        $hex_color .= $hex;
    }

    return $hex_color;
}

1;

__END__
