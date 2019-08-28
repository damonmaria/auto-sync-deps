# auto-sync-deps

Automatically keep your yarn dependencies in sync with git changes.

## Install

1. Due to limitations in [husky](https://github.com/typicode/husky/blob/next/DOCS.md)
   only do this with `package.json` in your git root (but auto-sync-deps will update other package trees as well)
2. `yarn add --dev auto-sync-deps`
3. Edit `package.json` and add the following to the top level:

```json
  "husky": {
    "hooks": {
      "post-checkout": "yarn sync-deps",
      "post-merge": "yarn sync-deps",
      "post-rewrite": "yarn sync-deps"
    }
  }
```

## What it does

When a change to a package tree (as in a change to a `yarn.lock`)
is pulled, merged, rebased, or checked out then that package tree is
updated. No more wondering why things aren't working because someone
has committed a package change and you haven't run `yarn`.

You can also force a manual update of all package trees with `yarn sync-deps`

## What this handles

- Multiple `package.json` package trees (but only install this package
  in the root one)
- Form the git hooks `yarn` is only run when that particular `yarn.lock` has changed
- In a Meteor project the Meteor version of node is used to ensure binary compatibility of compiled modules

## Possible improvements

- Make it work with npm's `package-lock.json` (could know to use `yarn`
  or `npm` based off `npm_config_user_agent` env var)
