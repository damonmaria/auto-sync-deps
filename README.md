# auto-sync-deps

Automatically keep your yarn dependencies in sync with upstream
changes.

## Install

1. `yarn add --dev auto-sync-deps`
2. Edit `package.json` and add the following to the top level:

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

- The `package.json` you install into can be anywhere in your git
    tree, it doesn't have to be in the root
- Multiple `package.json` package trees (but only install this package
    in one of them)
- Form the git hooks `yarn` is only run when the `yarn.lock` has changed
- In a Meteor project the Meteor version of node is used to ensure binary compatibility of compiled modules 

## Possible improvements

- Make it work with npm's `package-lock.json` (could know to use `yarn`
    or `npm` based off `npm_config_user_agent` env var)
