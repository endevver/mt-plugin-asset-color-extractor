package AssetColorExtractor::Plugin;

use strict;
use warnings;
use Image::Magick;
use Class::Load qw( load_class );
use Scalar::Util qw( blessed );

# Extract colors on file upload. This is for both the CMS and API callback
# methods.
sub upload_file_callback {
    my $cb = shift;
    my (%params) = @_;
    my $asset = $params{'Asset'};
    extract_color_async( $asset );
}

sub post_insert_callback {
    my ($cb, $app, $obj, $original) = @_;
    extract_color_async( $obj );
}

sub extract_color_async {
    shift if $_[0] eq __PACKAGE__; # supports method invocation
    my $a = shift;
    if ( blessed($a) && $a->isa('MT::Asset') ) {    # support MT::Asset object
        $a = { id => $a->id, blog_id => $a->blog_id }
    }
    elsif ( 'HASH' ne ref($a) ) {   # croak unless hash ref
        require Carp;
        Carp::croak(
              __PACKAGE__.'::extract_color_async takes single '
            . 'argument of either an MT::Asset object or a hashref containing '
            . 'the asset id and blog_id'
        );
    }

    my $job = load_class('TheSchwartz::Job')->new(
                  funcname  => 'AssetColorExtractor::Worker::Extract',
                  coalesce  => $a->{id},
                  uniqkey   => $a->{id},
                  priority  => 1,
              );

    # Insert and notify if job is new
    if (my $handle = load_class('MT::TheSchwartz')->insert($job)) {
        printf STDERR 'Color extraction job ID %d added for asset ID %s '
                    . "(blog ID:%s) at %s, line %s",
                    $handle->jobid, $a->{id}, $a->{blog_id}, __FILE__, __LINE__;
        return $handle;
    }
    return 1;
}

sub create_extract_color_worker {
    warn 'create_extract_color_worker is deprecated. '
        .'Please use extract_color_async';
    extract_color_async({ id => shift() });
}

# This method is executed by the post_init callback and explicitly defines
# the MT::Asset::extracted_colors method.
sub add_asset_method {
    # It is required by the gWizMobile Data API plugin in order to make
    # MT::DataAPI::Resource recognize extracted_colors as a valid asset field
    # (included by gWizMobile::DataAPI::Resource::Asset) and hence provision
    # the asset resource with its value.  It fails to do so because all meta
    # field methods are AUTOLOADed, MT::DataAPI::Resource uses UNIVERSAL::can()
    # to check for valid methods and AUTOLOADed methods are not visible to can()
    # (should use UNIVERSAL::DOES, I believe, or just try/eval)
    package MT::Asset {
        sub extracted_colors {
            shift()->meta('extracted_colors', @_);
        };
    };
}

# Do the actual color extraction. An image asset should have been provided.
# Reduce the color depth to even out the colors, then extract them based on the
# image histogram. Save as asset meta.
sub extract_color {
    my ($asset) = @_;

    return unless $asset && $asset->id && $asset->class =~ m/(image|photo)/;

    # We don't want to be able to re-extract colors over and over again...
    # right? I think the only use case is if the max number of extracted colors
    # has been changed, but as it's the *maximum* number to be extracted, that
    # won't necessarily even change any existing asset.
    return if $asset->extracted_colors;

    my $blog_id = $asset->blog_id;

    if (! -f $asset->file_path) {
        MT->instance->log({
            class    => 'Asset Color Extractor',
            category => 'extract_color',
            level    => MT->model('log')->ERROR(),
            blog_id  => $blog_id,
            message  => 'The Asset Color Extractor plugin could not read the'
                . ' specified file at ' . $asset->file_path . '.',
        });
        return;
    }

    my $image = Image::Magick->new;
    $image->Read( filename => $asset->file_path );

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
        push @saved_colors, $hist_entries[$i]->{hex}
            if $hist_entries[$i]->{hex};
    }

    # FIXME Dan Can @saved_colors ever be empty here? If so, handle it.

    $asset->extracted_colors( join(',', @saved_colors) );
    $asset->save or die $asset->errstr;

    MT->instance->log({
        class    => 'Asset Color Extractor',
        category => 'extract_color',
        level    => MT->model('log')->INFO(),
        blog_id  => $blog_id,
        message  => 'The Asset Color Extractor plugin saved the colors '
            . join(', ', @saved_colors) . ' from asset ID ' . $asset->id
            . ', file ' . $asset->file_path . '.',
    });

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
