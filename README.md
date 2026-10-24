# Brain Graph demo

A live, read-only demo of [Brain Graph](https://github.com/mfoll/brain-graph), the interactive map of a Markdown vault, running on nine fictional Second Brain vaults built from the [Second Brain template](https://github.com/mfoll/second-brain-template).

Open it at <https://mfoll.github.io/brain-graph-demo/> and pick a vault from the menu at the top left: a cancer genomics lab, a bakery, a community club, a freelance designer, a household, an HR team, a novelist, a startup engineering team and a teacher. Everything in them is fictional.

Everything works as in Brain Graph except what needs the local server: there is no **Open in Tolaria**, no adding vaults, and no live updates. Layout and settings changes, including saved views, stay in your browser; clear the site data to start again. **Replay agent** shows how notes pulse when an agent reads and writes them.

## What is here

- `site/` is the published site: Brain Graph's static build and, under `site/data/`, each vault's graph, notes, images, saved layout and settings.
- `vaults.json` lists the vaults and their labels; the first one opens by default.
- `state/` holds the layout and settings each vault starts with, in Brain Graph's own format (`layouts/<slug>.json`, `settings/<slug>.json`).
- `.github/workflows/pages.yml` publishes `site/` to GitHub Pages on every push to `main`. Nothing is built on GitHub.

## Rebuild

The site comes from Brain Graph's `main` branch (its static build) and from checkouts of the demo vaults next to this folder (`../second-brain-demo-cancer-lab` and the others named in `vaults.json`).

```bash
cd ../brain-graph && pnpm install && pnpm build:static
cd ../brain-graph-demo
rm -rf site && cp -R ../brain-graph/dist-static site && touch site/.nojekyll
node ../brain-graph/server/export-static.ts --config vaults.json --state state --out site
```

The export reads the vaults through Brain Graph's own server code, so the graph, note text and images are what the local app would show. It leaves out absolute paths and files in dot-folders.

A vault without a layout in `state/` is laid out in each visitor's browser. To save one, open the vault once in a local Brain Graph and copy its `~/.config/brain-graph/layouts/<slug>.json` into `state/layouts/`.

To try the site locally under the same sub-path as on GitHub Pages:

```bash
mkdir -p /tmp/pages && ln -sfn "$PWD/site" /tmp/pages/brain-graph-demo
python3 -m http.server 8000 -d /tmp/pages   # then open http://localhost:8000/brain-graph-demo/
```

## Licence

Brain Graph and the demo vaults are MIT licensed, and so is this site; see [LICENSE](LICENSE).
