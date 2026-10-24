#!/usr/bin/env bash
# Rebuilds site/ from the latest Brain Graph release and fresh clones of the vaults in vaults.json.
# Run from the repository root. Needs git, curl, jq, Node.js 22.18 or newer and pnpm.
#
#   scripts/rebuild.sh          rebuild only if sources.json would change
#   scripts/rebuild.sh --force  rebuild anyway
#
# sources.json records the Brain Graph release and the vault commits the site was built from.
# Set GITHUB_TOKEN to raise the GitHub API rate limit; the sources are public, so it is optional.
set -euo pipefail

root=$(pwd)
[ -f "$root/vaults.json" ] || { echo "run from the brain-graph-demo root" >&2; exit 1; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
tag=$(curl -fsSL ${auth[@]+"${auth[@]}"} https://api.github.com/repos/mfoll/brain-graph/releases/latest | jq -r .tag_name)
refs=$(git ls-remote https://github.com/mfoll/brain-graph.git "refs/tags/$tag" "refs/tags/$tag^{}")
commit=$( (grep '\^{}$' <<<"$refs" || cat <<<"$refs") | head -1 | cut -f1)  # prefer the peeled commit of an annotated tag
[ -n "$commit" ] || { echo "cannot resolve Brain Graph $tag" >&2; exit 1; }

vaults='{}'
for repo in $(jq -r '.[].path | sub("^\\.\\./"; "")' vaults.json); do
  head=$(git ls-remote "https://github.com/mfoll/$repo.git" HEAD | cut -f1)
  [ -n "$head" ] || { echo "cannot resolve $repo" >&2; exit 1; }
  vaults=$(jq --arg r "$repo" --arg h "$head" '. + {($r): $h}' <<<"$vaults")
done
jq -n --arg tag "$tag" --arg commit "$commit" --argjson vaults "$vaults" \
  '{"brain-graph": {release: $tag, commit: $commit}, vaults: $vaults}' > "$work/sources.json"

if [ "${1:-}" != "--force" ] && [ -f sources.json ] && cmp -s sources.json "$work/sources.json"; then
  echo "unchanged: Brain Graph $tag and all vaults match sources.json"
  exit 0
fi

echo "building Brain Graph $tag ($commit)"
git init -q "$work/brain-graph"
git -C "$work/brain-graph" fetch -q --depth 1 https://github.com/mfoll/brain-graph.git "$commit"
git -C "$work/brain-graph" checkout -q FETCH_HEAD
(cd "$work/brain-graph" && pnpm install --frozen-lockfile --ignore-scripts && pnpm build:static)

mkdir "$work/config"
cp vaults.json "$work/config/vaults.json"
for repo in $(jq -r 'keys[]' <<<"$vaults"); do
  git clone -q "https://github.com/mfoll/$repo.git" "$work/$repo"
  [ "$(git -C "$work/$repo" rev-parse HEAD)" = "$(jq -r --arg r "$repo" '.[$r]' <<<"$vaults")" ] \
    || { echo "$repo moved during the build; run again" >&2; exit 1; }
  # Brain Graph reads each note's modification time. A clone stamps every file with the clone time,
  # so set it to the file's last commit instead: the output then repeats exactly and edit recency
  # follows the vault's own history.
  python3 - "$work/$repo" <<'PY'
import os, subprocess, sys
repo = sys.argv[1]
log = subprocess.run(["git", "-C", repo, "log", "--format=%x00%ct", "--name-only", "--no-renames"],
                     capture_output=True, text=True, check=True).stdout
seen, when = set(), None
for line in log.split("\n"):
    if line.startswith("\0"):
        when = int(line[1:])
    elif line and line not in seen:
        seen.add(line)
        path = os.path.join(repo, line)
        if os.path.isfile(path):
            os.utime(path, (when, when))
PY
done

cp -R "$work/brain-graph/dist-static" "$work/site"
touch "$work/site/.nojekyll"
# Files served from the site for other pages (the README animation in media/) are kept outside site/,
# which this script replaces, and copied in.
[ -d "$root/media" ] && cp -R "$root/media" "$work/site/media"
node "$work/brain-graph/server/export-static.ts" --config "$work/config/vaults.json" --state "$root/state" --out "$work/site"

# Privacy check before publishing: no absolute paths, no mention of the maintainer's employer
# (the demos must not draw on its material), and nothing shaped like a credential.
check() { # label, extended regex, case-insensitive flag
  if grep -rIl $3 -E "$2" "$work/site/data" >/dev/null; then
    echo "privacy check failed ($1); not publishing:" >&2
    grep -rIl $3 -E "$2" "$work/site/data" | sed "s|$work/||" >&2
    exit 1
  fi
}
check "absolute path" "$work|/home/runner|/Users/" ""
check "employer" "iarc|who\.int" -i
check "credential" "AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36}|github_pat_|sk-[A-Za-z0-9]{20}|BEGIN [A-Z ]*PRIVATE KEY" ""

rm -rf "$root/site"
cp -R "$work/site" "$root/site"
cp "$work/sources.json" "$root/sources.json"
echo "rebuilt site/ from Brain Graph $tag and $(jq 'length' <<<"$vaults") vaults"
