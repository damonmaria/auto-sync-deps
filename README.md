# auto-sync-deps

Automatically keep your yarn and pipenv dependencies in sync with git changes.

## Install

1. Due to limitations in [husky](https://github.com/typicode/husky/blob/next/DOCS.md)
   only do this with `package.json` in your git root (but auto-sync-deps will update other package trees as well)
2. `yarn add --dev auto-sync-deps`
3. Edit root `package.json` and add the following to the top-level:
   ```json
   {
     "name": "...",
     "...": "...",
     "husky": {
       "hooks": {
         "post-checkout": "yarn sync-deps",
         "post-merge": "yarn sync-deps",
         "post-rewrite": "yarn sync-deps"
       }
     }
   }
   ```
4. To manage python Pipfile's both `pipenv` and `pyenv` need to be installed

## What it does

When a change to a package tree (as in a change to a `yarn.lock` or `Pipfile.lock`)
is pulled, merged, rebased, or checked out then update that package tree.
No more wondering why things aren't working because someone has
committed a package change, but you still have an older version installed.

You can also force a manual update of all package trees with `yarn sync-deps`

## What this handles

- Multiple `package.json`, `Pipenv`, and `Poetry` package trees (but only install this package
  in the root one)
- Form the git hooks the installation is only run when that particular lock file has changed
- Install the latest version of the python specified in the Pipfile using `pyenv`
- In a Meteor project use the Meteor version of node to ensure binary compatibility of compiled modules

## Possible improvements

- Make it work with npm's `package-lock.json` (could know to use `yarn`
  or `npm` based off `npm_config_user_agent` env var)

## Development

### Release

`yarn publish --major` or `yarn publish --minor` or `yarn publish --patch` depending on the change 
