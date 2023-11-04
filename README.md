![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/wokwi_test/badge.svg)

# Analog Clock using a beam-racing triangle render

The VGA timing is based directly on VEGA 640x480 @ 75 Hz.

Using a tile-based beam-racing triangle render has always seemed like
a good way to deal with the lack of a framebuffer. Tiny Tapeout gave
me an opportunity to play with it.  However as this effort is pretty
much defined by a mad-scramble to get SOMETHING done for Nov 4th
everything is a consequence of that, so the design is very simple and
not very ambitious.

Every frame the 640x480 VGA matrix is scanned, advancing the state of
the intersecting lines of the three triangles.  If the (x,y)
coordinate of the "beam" lines on the positive side of each line, the
beam is inside the triangle.  Among the visible triangles, the highest
priority triangle sets the color, else we default to a grey color.
Twelve dots are also marked, to make it easier to read the clock.

The algorithm might be easily understood by examining the software
model in Rust, in the `sw` directory.

The main "UI" is two buttons to advance hour and minutes respectively.
The least significant two bits selects which outputs are routed to the
bidirectional port (frame number, seconds * 4 + hz-strobe * 2 +
vs-strobe, minute * 4, hour * 4).

# What is Tiny Tapeout?

TinyTapeout is an educational project that aims to make it easier and cheaper than ever to get your digital designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Wokwi Projects

Edit the [info.yaml](info.yaml) and change the wokwi_id to the ID of your Wokwi project. You can find the ID in the URL of your project, it's the big number after `wokwi.com/projects/`.

The GitHub action will automatically fetch the digital netlist from Wokwi and build the ASIC files.

## Verilog Projects

Edit the [info.yaml](info.yaml) and uncomment the `source_files` and `top_module` properties, and change the value of `language` to "Verilog". Add your Verilog files to the `src` folder, and list them in the `source_files` property.

The GitHub action will automatically build the ASIC files using [OpenLane](https://www.zerotoasiccourse.com/terminology/openlane/).

## Enable GitHub actions to build the results page

- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://discord.gg/rPK2nSjxy8)

## What next?

- Submit your design to the next shuttle [on the website](https://tinytapeout.com/#submit-your-design). The closing date is **November 4th**.
- Edit this [README](README.md) and explain your design, how it works, and how to test it.
- Share your GDS on your social network of choice, tagging it #tinytapeout and linking Matt's profile:
  - LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [matt-venn](https://www.linkedin.com/in/matt-venn/)
  - Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
  - Twitter [#tinytapeout](https://twitter.com/hashtag/tinytapeout?src=hashtag_click) [@matthewvenn](https://twitter.com/matthewvenn)

