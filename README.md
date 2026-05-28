# auto-sync-deps

Automatically keep your JavaScript and Python dependencies in sync with git changes.

## Install

1. `pnpm add --save-dev husky auto-sync-deps`
2. `npx husky init`
3. `echo "npx --no-install sync-deps" > .husky/post-checkout`
4. `echo "npx --no-install sync-deps" > .husky/post-merge`
5. `echo "npx --no-install sync-deps" > .husky/post-rewrite`

## What it does

When a change to a package tree (as in a change to a `pnpm-lock.yaml`, `uv.lock`, etc.)
is pulled, merged, rebased, or checked out then update that package tree.
No more wondering why things aren't working because someone has
committed a package change, but you still have an older version installed.

You can also force a manual update of all package trees with `npx sync-deps`

## What this handles

- Multiple `package.json`, `pyproject.toml` package trees
- From the git hooks the installation is only run when that particular lock file has changed

### Release

`npm publish` 
