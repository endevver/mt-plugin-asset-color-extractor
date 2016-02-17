package AssetColorExtractor::CMS;

use strict;
use warnings;

use AssetColorExtractor::Plugin;

# Add a column to the Assets listing framework page to display extracted colors.
sub colors_column_list_property {
    my $prop = shift;
    my ( $obj, $app, $opts ) = @_;

    my @colors = split(',', ($obj->meta('extracted_colors')||''));

    my $html = '';

    foreach my $color (@colors) {
        $html .= '<div style="width: 20px; height: 20px; '
            . 'border: 1px solid #ccc; display: block; float: left; '
            . 'overflow: hidden; margin: 0 5px 5px 0; '
            . 'background-color: ' . $color
            . '" title="color: ' . $color . '"></div>';
    }

    return $html;
}

# Add the "Extract Color" list action to the Assets listing framework page.
sub list_action_extract_color {
    my ($app) = @_;
    $app->validate_magic or return;
    my $q = $app->can('query') ? $app->query : $app->param;
    my @asset_ids = $q->param('id');

    for my $asset_id (@asset_ids) {
        my $asset = $app->model('asset')->load({
            id    => $asset_id,
            class => ['image', 'photo'], # Can only extract from images.
        })
            or next;

        # Create a Worker to do the color extraction.
        AssetColorExtractor::Plugin::create_extract_color_worker( $asset->id );
    }

    $app->add_return_arg( color_extracted => 1 );
    $app->call_return;
}

# Add the "Extract Color" page action to the Edit Asset screen.
sub page_action_extract_color {
    my ($app) = @_;
    $app->validate_magic or return;
    my $q = $app->can('query') ? $app->query : $app->param;
    my $asset_id = $q->param('id');

    my $asset = $app->model('asset')->load({
        id    => $asset_id,
        class => ['image', 'photo'], # Can only extract from images.
    })
        or next;

    # Create a Worker to do the color extraction.
    AssetColorExtractor::Plugin::create_extract_color_worker( $asset->id );

    $app->add_return_arg( color_extracted => 1 );
    $app->call_return;
}

# Can the "Extract Color" page action be displayed for this asset? Check that
# it's an image asset first.
sub page_action_condition {
    my ($app) = MT->instance;
    my $q = $app->can('query') ? $app->query : $app->param;
    my $asset_id = $q->param('id');

    return 1 if $app->model('asset')->exist({
        id    => $asset_id,
        class => ['image', 'photo'], # Can only extract from images.
    });
    
    return 0;
}

# Add the extracted colors to the Edit Asset screen.
sub add_asset_meta {
    my ( $cb, $app, $param, $tmpl ) = @_;

    return if $param->{asset_type} !~ m/(image|photo)/;

    my $asset = $app->model('asset')->load( $param->{id} )
        or die $app->model('asset')->errstr;

    my $colors_field = $tmpl->createElement(
        'app:setting',
        {
            id    => 'extracted_colors',
            label => 'Extracted Colors',
        }
    );

    my $html = '';
    foreach my $color ( split(',', ($asset->extracted_colors||'')) ) {
        $html .= '<div style="width: 50px; height: 50px; '
            . 'border: 1px solid #ccc; display: block; float: left; '
            . 'overflow: hidden; margin: 0 5px 5px 0; '
            . 'background-color: ' . $color
            . '" title="color: ' . $color . '"></div>';
    }

    if (! $html) {
        $html = '<p style="padding-top: 3px">(No colors have been extracted.)</p>';
    }

    $colors_field->innerHTML( $html );

    my $tags_field = $tmpl->getElementById('asset-url')
        or die MT->log('Cannot identify the Asset URL field block in template');

    $tmpl->insertAfter( $colors_field, $tags_field )
        or die MT->log('Failed to insert the Camera Metadata field into template.');
}

1;

__END__
