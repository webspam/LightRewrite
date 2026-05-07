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

## Image comparison sliders

The site uses [`img-comparison-slider`](https://github.com/sneas/img-comparison-slider) (v8, loaded from jsDelivr CDN).

### HTML pattern

```html
<div class="comparison-slider-bleed" markdown="0">
  <img-comparison-slider>
    <img
      slot="first"
      alt="description-before"
      src="https://webspam.github.io/images/<before>.jpg"
    />
    <img
      slot="second"
      alt="description-after"
      src="https://webspam.github.io/images/<after>.jpg"
    />
  </img-comparison-slider>
</div>

<p class="image-compare-links">
  <a href="https://webspam.github.io/images/<before>.jpg">Before</a> |
  <a href="https://webspam.github.io/images/<after>.jpg">After</a>
</p>
```

- `markdown="0"` on the wrapper div is required — it prevents Jekyll/Kramdown from mangling the custom element markup inside.
- Do **not** set `width="100%"` on the `<img>` tags; the CSS handles sizing.
- The `.comparison-slider-bleed` class makes the slider break out of the content column for a full-bleed effect with a 2 rem inset on each side.

## File layout

```
docs/
  _config.yml                        # Jekyll config
  index.md                           # Home page (layout: home)
  AGENTS.md                          # This file
  _includes/
    custom-head.html                 # Loads img-comparison-slider CSS + JS from CDN
  _sass/minima/
    custom-styles.scss               # Bleed slider layout + link styles
  assets/css/
    style.scss                       # Imports minima sass (required by remote theme)
```
