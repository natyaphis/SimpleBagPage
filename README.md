# SimpleBagPage

SimpleBagPage is a small World of Warcraft addon that adjusts the default Blizzard bag UI.

Current behavior:

- Sets the overall bag scale to `0.9`
- Sets the horizontal gap between the combined bag and reagent bag to `-3`
- Adjusts stack count font, size, outline, and anchor
- Tries to stay compatible with ElvUI when ElvUI is repositioning the default Blizzard bags

## Files

- `SimpleBagPage.lua`: addon logic
- `SimpleBagPage.toc`: addon metadata

## Customization

Edit the `CONFIG` table near the top of [SimpleBagPage.lua](SimpleBagPage.lua).

Important fields:

- `bagScale`
- `combinedReagentGapX`
- `combinedReagentGapY`
- `countFont`
- `countFontSize`
- `countOutline`
- `countAnchor`

If you want to use a custom font, `countFont` must be a real font file path, for example:

```lua
countFont = "Interface\\AddOns\\SimpleBagPage\\Media\\Bauhaus.ttf"
```

## Installation

Copy the `SimpleBagPage` folder into your WoW AddOns directory:

`World of Warcraft/_retail_/Interface/AddOns/SimpleBagPage`

Then reload the UI or restart the game.
