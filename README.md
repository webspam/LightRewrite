# Light Rewrite, or Next Gen Lighting Fix

_Edits lights like candles and torches to be next-gen ray trace friendly, by editing the entities at runtime._

## The problem

Most light sources in the game were designed to only influence a tiny little sphere. Witcher 3 was written for 2015 hardware; a candle was intended to tint and highlight objects sitting right in front of it, not light an entire room. Scene lighting was handled by **much** cheaper lighting tricks.

With modern RT lighting, the result is tiny spheres of super-bright light, that end abruptly on an inexplicable ocean of blackness.

## The traditional solution

You could update every level and light source to use modern lighting styles. Folks have done this before. Editing level files requires diligence to do cleanly, is a huge job to do once, and maintaining it is actually worse. Most lighting mods have been abandoned and are often compatibility nightmares for users.

Unless CDPR gives us a new baseline, this is just impractical.

## Introducing: dirty hax

This mod instead edits the properties of lights at runtime. When entities are first spawned, light sources are identified and classified (in a semi-optimised way, purportedly). Candles get edited to have more candle-like candlelight. Torches get torched. etc.

---

#### Caveats and other fine print

This isn't perfect. The matching is naïve; a light source named `glowing_altar_without_candles.w2ent` in the editor will be misidentified as a candle / cluster of candles.

I _guarantee_ this will not work with **every** combination of mods.

That said, I'm extremely keen (at time of writing) to hear about any misidentified light sources or terrible results. ... assuming you can give me a screen shot and a mod list.
