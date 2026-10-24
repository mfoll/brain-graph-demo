# Brain Graph demo

A live, read-only demo of [Brain Graph](https://github.com/mfoll/brain-graph), the interactive map of a Markdown vault, running on nine fictional Second Brain vaults built from the [Second Brain template](https://github.com/mfoll/second-brain-template).

Open it at <https://mfoll.github.io/brain-graph-demo/> and pick a vault from the menu at the top left: a cancer genomics lab, a bakery, a community club, a freelance designer, a household, an HR team, a novelist, a startup engineering team and a teacher. Everything in them is fictional. Each vault is also a repository you can clone and open in any Markdown editor; the [Second Brain template](https://github.com/mfoll/second-brain-template#example-vaults) lists all nine.

Everything works as in Brain Graph except what needs the local server: there is no **Open in Tolaria**, no adding vaults, and no live updates. Layout and settings changes, including saved views, stay in your browser; clear the site data to start again. **Replay agent** plays a short made-up session of two agents, built from the vault's own links, so you can see notes pulse blue as they are read and red as they are written, and a dot run along each link an agent follows.

## What is here

- `site/` is the published site: Brain Graph's static build and, under `site/data/`, each vault's graph, notes, images, saved layout and settings.
- `vaults.json` lists the vaults and their labels; the first one opens by default.
- `state/` holds the layout and settings each vault starts with, in Brain Graph's own format (`layouts/<slug>.json`, `settings/<slug>.json`).
- `sources.json` records the Brain Graph release and the commit of each vault the site was built from.
- `media/` holds files other pages use from this site, such as the Brain Graph animation in the Second Brain template's README. Each rebuild copies it into `site/media/`.
- `.github/workflows/rebuild.yml` runs `scripts/rebuild.sh` once a day (05:41 UTC) and on demand: start it from the Actions tab right after a Brain Graph release. When a new Brain Graph release or a vault commit changes `sources.json`, it commits the rebuilt `site/` and deploys it; otherwise it stops.
- `.github/workflows/pages.yml` publishes the committed `site/` to GitHub Pages on every push to `main`.

## Rebuild

The site is built from Brain Graph's latest release and fresh clones of the vaults named in `vaults.json`. Each note's modification time is set to its last commit, so a rebuild of the same sources produces the same files and Brain Graph's edit-recency view follows the vault's history.

To rebuild by hand, you need Git, jq, Python 3, pnpm and Node.js 22.18 or newer (the export runs a TypeScript file directly):

```bash
scripts/rebuild.sh            # only if a source changed
scripts/rebuild.sh --force    # anyway
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
