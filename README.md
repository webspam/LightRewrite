# Light Rewrite

_Updates lights like candles and torches to be path/ray-trace friendly, by editing the entities at runtime._

## Comparisons

<https://webspam.github.io/LightRewrite/gallery>

## New features

- Player & NPC torch / lantern customisation
  - Customisation options are now available in the mod menu. For existing users, it is **off** by default. New users default to enabled, with some less intense settings.
- Interior fog removal (0-100%)
  - Off by default for everyone.
  - Located in the new **Advanced** submenu.
  - Configurable removal strength & transition duration.
- Gameplay light removal (artificial player light)
  - A slider that lets you adjust the strength of the "gameplay light", that shines from behind the camera. **Off** by default.
- **Distant lights** are now visible from significantly further away (~0fps impact)
- **Ultra profile** for anyone with beefy hardware and FPS to spare

## Remastered

The mod supports and will continue to be updated for Remastered. The remaining lights are being knocked out quickly. If you find anything out of place - please let me know.

Remastered addressed a lot of lighting issues, but it also created some new ones, like hyper-bright glare from tiny candles. It also made it possible to _really_ push lighting - better reach, saturation/bleed, and colours.

Once the default Light Rewrite profile is finalised, more can be added easily.

### Introducing: dirty hax

This mod edits the properties of lights at runtime. When entities are first spawned, light sources are identified and classified (in a semi-optimised way, purportedly). Candles get edited to have more candle-like candlelight. Torches get torched. etc.

#### Before

<img width="3840" height="1440" alt="vizima-welcome-before-219" src="https://github.com/user-attachments/assets/0c185c38-c12e-48b0-ac2d-968e8fd7f641" />

#### After

<img width="3840" height="1440" alt="vizima-welcome-after-219" src="https://github.com/user-attachments/assets/9efcdcec-d6f8-4aae-ac18-ed0da16f8997" />

---

#### Caveats and other fine print

This isn't perfect. It should run conflict-free with nearly everything, but I won't guarantee **every** combination of mods.

That said, I'm extremely keen (at time of writing) to hear about any misidentified light sources or terrible results. ... assuming you can give me a screen shot and a mod list.

---

## Installation instructions

**Mod manager**

1. Install with W3MM / Vortex

**Manual install**

1. Copy the zip contents into the game directory.

May be installed / uninstalled at any time, without breaking the game.

### Requirements

- None

### Works with

- The Witcher 3 Remastered
- The Witcher 3 Next Gen - 4.04
- RT on/off
- PT on/off
- DX 11/12
- Mods
  - Cozy RTX
  - Lighting mods

## Credits

- [Cohgent](https://www.nexusmods.com/profile/Cohgent) - Honeyfill Meadworks
- [Antigon09](https://www.nexusmods.com/profile/Antigon09) - Translation corrections (many)

### Old 4.04 info

<details>
<summary>Show</summary>

#### The problem (4.04)

Most light sources in the game were designed to only influence a tiny little sphere. Witcher 3 was written for 2015 hardware; a candle was intended to tint and highlight objects sitting right in front of it, not light an entire room. Scene lighting was handled by **much** cheaper lighting tricks.

With modern RT lighting, the result was tiny spheres of super-bright light, that end abruptly on an inexplicable ocean of blackness.

#### The traditional solution (4.04)

You could update every level and light source to use modern lighting styles. Folks have done this before. Editing level files requires diligence to do cleanly, is a huge job to do once, and maintaining it is actually worse. Most lighting mods have been abandoned and are often compatibility nightmares for users.

Unless CDPR gives us a new baseline, this is just impractical. [This statement aged well..]

#### Next-Gen 4.04 Requirements

- [Community Patch - Shared Imports](https://www.nexusmods.com/witcher3/mods/2110)

</details>
