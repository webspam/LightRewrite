# Agent guidance for Light Rewrite

## Most important rule: read the README before touching a directory

**Before making any change in a directory, read the `README.md` in that directory.**
README files contain the context essential for making correct changes — design decisions,
constraints, and behavioural descriptions. They are written for both humans and agents.

Skipping them leads to changes that conflict with existing conventions or break assumptions that are not obvious from the code alone.

This applies at every level: root README, `debug/README.md`, `debug/editor/README.md`, `src/xml/README.md`, and any others. Navigate to the README nearest to the code you are changing and read it first.

## Repository overview

Light Rewrite is a Witcher 3 (Next-Gen) mod written in WitcherScript. It adjusts light
source properties at runtime so that candles, torches, and similar entities behave well
under modern ray-traced lighting — without editing level files.

### .cursor/rules/

`.cursor/rules/` contains agent rules for this project. The directory is gitignored
(it mixes project-level and local-only rules), but the rules inside are active and
should be followed. Do not delete or recreate the directory.
