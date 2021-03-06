# Asset Color Extractor

This plugin for Movable Type will look at any image asset and extract a set of
colors from the image.

# Prerequisites

* Image Magick
* Movable Type 6.2+
* `run-periodic-tasks` must be set up

# Configuration

The maximum number of colors to be extracted can be specified on a per-blog
basis. Visit Tools > Plugins > Asset Color Extractor > Settings to specify this
option. Note that the option is the *maximum* number of colors to be extracted.
Simple or small images can return few results. "5" is likely a good balance
between what can be extracted from images; some less complex images may only
find one, two, or three colors and only the most complex images will return
more than ten.

The colors are identified based upon commonality and frequency of use in the
image histogram. Most typically, this means that the images background colors
are going to appear in the palette first while less common colors will be at
the end of the palette. The plugin reduces the image's complexity to find a
color palette and this can also mean that a given color's frequency is not high
enough in the histogram to extract that color. In other words, it's not a
perfect tool.

If you want to use a color to blend in with the image, the first extracted
color is likely a good choice. Better accent color choices can likely be found
further along in the palette -- perhaps the 3rd or 5th color extracted, for
example.

# Use

The Asset Color Extractor plugin can be used to extract colors in a number of
ways:

* Automatically, on upload.
* With the "Extract Colors" Page Action on the Edit Asset screen.
* With the "Extract Colors" List Action on the Manage Assets screen. (Choose
  assets then select "Extract Colors" from the "Actions..." dropdown.)

Need to extract colors from all existing assets, and you've got a lot of
assets? Included is a small script to help: `extract-colors.pl`. From your
MT_HOME, run `./plugins/AssetColorExtractor/extract-colors.pl` to process all
image assets in the system. Restrict it by adding the blog ID, for example
`./plugins/AssetColorExtractor/extract-colors.pl 7` to extract colors only for
assets in blog ID 7.

All of these extraction methods work the same way, creating a new Worker for
each asset. This is where `run-periodic-tasks` comes in: the extraction worker
is run by `run-periodic-tasks` (informally, the "Publish Queue"). This also
means that when choosign to extract colors they are typically not going to be
available immediately; you must wait until the Worker finishes. Why do it this
way? Most image assets can extract a color palette pretty quickly, but I found
that some assets would take a long time to parse (often upwards of one minute).
The commonality I found amongst image assets that took a long time to process
wasn't file size or pixel dimensions, but sharpness. Images that are *not
quite* sharp took quite a while. The only reasonable way to handle this, then,
was to offload the extraction to another process that wouldn't leave the user
waiting.

Extracted colors can be reviewed in two ways:

* The Edit Asset screen will show an "Extracted Colors" section which presents
  large samples of the extracted colors.
* The Manage Assets screen includes a new column for the Listing Framework,
  "Extracted Colors," which presents small samples of the extracted colors.


# Template Tags

Two template tags are provided to make working with the extracted colors easy.
Your template must be in the Asset context to use these tags.

## AssetExtractedColors

The `AssetExtractedColors` block tag provides access to all of the extracted
colors. It has no arguments. The meta variables `__first__`, `__last__`,
`__even__`, `__odd__`, and `__counter__` can be used with this tag. Example use
is below.

The `AssetExtractedColors` block tag takes one argument: `generate`. Setting
this argument to true (`1`) will cause the tag to extract colors from the image
if not already availabe. This can be a good way to extract colors from older
assets, but note that it can be resource intensive!

## AssetExtractedColor

The `AssetExtractedColor` function tag outputs the extracted color. This can be
used with the `AssetExtractedColors` block tag. Example:

    <mt:Assets>
    <p>
        <mt:AssetLabel>:
        <mt:AssetExtractedColors>
        <span style="width: 20px; height: 20px; display: inline-block;
            background-color: <mt:AssetExtractedColor>">
            <mt:Var name="__counter__">
        </span>
        </mt:AssetExtractedColors>
    </p>
    </mt:Assets>

The `AssetExtractedColor` tag can also be used without the
`AssetExtractedColors` tag to output just one color by specifying the `index`
argument, which requires an integer. The following example publishes the second
color in the extracted palette:

    <mt:Assets>
    <p>
        <mt:AssetLabel>:
        <span style="width: 20px; height: 20px; display: inline-block;
            background-color: <mt:AssetExtractedColor index="2">">
            my color
        </span>
    </p>
    </mt:Assets>

The `AssetExtractedColor` tag will try to output the requested color. If it's
not available, however, it will ourput the previously available color. For
example, if a palette of three colors has been found and the template includes
`<mt:AssetExtractedColor index="5">`, the then tag will output the third (last)
color in the palette.

Additionally, the `AssetExtractedColor` tag supports the `generate` argument.
Setting this argument to true (`1`) will cause the tag to create a Worker to
extract colors from the image if not already available. This can be a good way
to extract colors from older assets, too.

    <mt:Assets>
    <p>
        <mt:AssetLabel>:
        <span style="width: 20px; height: 20px; display: inline-block;
            background-color: <mt:AssetExtractedColor index="2" generate="1">">
            my color
        </span>
    </p>
    </mt:Assets>

# License

This plugin is licensed under the same terms as Perl itself.

#Copyright

Copyright 2016, Endevver LLC. All rights reserved.
