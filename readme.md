# Asset Color Extractor

This plugin for Movable Type will look at any image asset and extract a set of
colors from the image.

# Prerequisites

* Image Magick
* Movable Type 6.2+

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

# License

This plugin is licensed under the same terms as Perl itself.

#Copyright

Copyright 2016, Endevver LLC. All rights reserved.
