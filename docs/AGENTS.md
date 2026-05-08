# GitHub Pages — Agent Notes

## Deployment

- The site lives exclusively on the **`gh-pages` branch**. Normal git workflow rules do **not** apply here.
- To deploy: commit changes on `gh-pages` and `git push origin gh-pages`. GitHub Pages picks it up automatically — no CI step needed.
- Do **not** create feature branches or PRs for docs changes; push directly to `gh-pages`.

## URLs & repository layout

| Thing          | Value                                          |
| -------------- | ---------------------------------------------- |
| Site URL       | `https://webspam.github.io/LightRewrite`       |
| Source repo    | `https://github.com/webspam/LightRewrite`      |
| Image repo     | `https://github.com/webspam/webspam.github.io` |
| Image base URL | `https://webspam.github.io/images/`            |

Images are **not** stored in this repo. Upload images to the `webspam/webspam.github.io` repo under `/images/`, then reference them as `https://webspam.github.io/images/<filename>`.

The images repo **may** be available locally, in a directory adjacent to this repo.

## Jekyll configuration (`_config.yml`)

- Theme: `jekyll/minima` pinned to a specific commit via `remote_theme` (not the gem). If explicitly requested, you can update the theme by updating the commit SHA to pull in upstream changes.
- Skin: `dark`.
- `titles_from_headings.strip_title: true` — prevents duplicate `<h1>` when `jekyll-titles-from-headings` (loaded by GitHub Pages by default) promotes the first heading to `page.title`.
- `url` + `baseurl` are set so absolute URLs and assets resolve correctly for a project site (not a user/org site).
- `AGENTS.md` is in the `exclude` list so it is not published to the site.

## Third-party libraries (loaded from jsDelivr CDN)

| Library               | Version | Purpose                                    |
| --------------------- | ------- | ------------------------------------------ |
| `img-comparison-slider` | 8     | Before/after drag slider inside each slide |
| `swiper`              | 12      | Main gallery carousel + thumbnail strip    |
| `lucide`              | latest  | Expand/collapse icon in gallery footer     |

All three are loaded in `_includes/custom-head.html`. Swiper and Lucide are loaded synchronously (no `defer`); the comparison slider uses `defer`.

## Gallery structure

The main page (`index.md`) contains a single `.gallery-wrap` div (with `markdown="0"`) that holds:

1. **Main Swiper** — fade-effect carousel, one slide per scene. Each slide has:
   - `.slide-title` — scene name
   - `.slide-image-wrap` — flex container that centres the slider and anchors nav arrows
   - `.slider-wrap` — inline-block wrapper that shrink-wraps to the image width so Before/After labels anchor to the image edges
   - `<img-comparison-slider>` — the before/after element (see pattern below)
   - `.swiper-button-prev` / `.swiper-button-next` — Swiper nav arrows, positioned inside `.slide-image-wrap`

2. **Thumbnail strip** — a second `.swiper.swiper-thumbs` below the main swiper, linked via Swiper's `thumbs` option.

3. **Gallery footer** — an Expand/Collapse button (`.expand-btn`) that toggles `.is-expanded` on `.gallery-wrap`, breaking it out to near-full viewport width.

Swiper is initialised and the expand toggle is wired up in an inline `<script>` at the bottom of `index.md`.

### Comparison slider HTML pattern

```html
<img-comparison-slider>
  <figure slot="first">
    <img src="https://webspam.github.io/images/<before>.jpg" alt="Scene name — before" />
    <figcaption>Before</figcaption>
  </figure>
  <figure slot="second">
    <img src="https://webspam.github.io/images/<after>.jpg" alt="Scene name — after" />
    <figcaption>After</figcaption>
  </figure>
</img-comparison-slider>
```

- The `<figcaption>` elements provide the Before/After corner labels. They live inside `slot="first/second"` so the slider's clipping mask hides them naturally as the handle moves — no JS needed.
- Do **not** set `width="100%"` on the `<img>` tags; images render at intrinsic size and CSS caps them with `max-width: 100%`.
- Do **not** use the old `<div class="comparison-slider-bleed">` wrapper or `<p class="image-compare-links">` pattern — those are obsolete.

### Adding a new slide

1. Add a `.swiper-slide` block to the main swiper in `index.md` (copy an existing slide, update title, image URLs, and `alt` text).
2. Add a matching `.swiper-slide` entry (thumbnail image only) to the `.swiper-thumbs` strip — order must match the main swiper.

## File layout

```
docs/
  _config.yml                        # Jekyll config
  index.md                           # Home page (layout: home) — contains gallery markup + inline JS
  AGENTS.md                          # This file (excluded from Jekyll build)
  _includes/
    custom-head.html                 # Loads img-comparison-slider, Swiper, and Lucide from CDN
  _sass/minima/
    custom-styles.scss               # Minima overrides (if any)
  assets/css/
    style.scss                       # Imports minima sass (required by remote theme)
    gallery.scss                     # Gallery layout: Swiper, comparison slider, expand toggle, thumbnails
```
