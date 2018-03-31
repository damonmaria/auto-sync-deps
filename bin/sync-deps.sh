#!/usr/bin/env bash

if [[ ${GIT_PARAMS+foo} ]]; then  # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
    # GIT_PARAMS exists therefore called by husky git hook
	if [[ -z ${GIT_PARAMS} ]]; then
		# Git provides no params for post-merge hook
		GIT_PARAMS="ORIG_HEAD HEAD"
	fi
	GIT_PATHS=$(git diff-tree -r --name-only --no-commit-id ${GIT_PARAMS})
else
	# Sync everything
	GIT_PATHS=$(git ls-tree --full-tree -r --name-only HEAD)
	if [[ ${npm_lifecycle_event} == "postinstall" ]]; then
		INSTALLED_IN_PKG_DIR=$(cd .. && npm prefix)  # Can't see how else to figure out where is the package.json we're being installed into
		# Don't try and install the package tree that we're already in the middle of installing
		SKIP_LOCK_PATH=$(git ls-tree --full-name --name-only HEAD "${INSTALLED_IN_PKG_DIR}/yarn.lock")  # So path is same format that we need to match to
	fi
fi

cd $(git rev-parse --show-toplevel)  # Run everything from the root of the git tree to match the GIT_PATHS

echo "${GIT_PATHS}" | grep "\(^\|/\)yarn.lock$" | while read -r LOCK_PATH ; do
	if [[ ${LOCK_PATH} == ${SKIP_LOCK_PATH} ]]; then
		continue
	fi
	PKG_DIR=$(dirname ${LOCK_PATH})
	if [[ ${GIT_PARAMS} ]]; then
		echo Updating dependencies due to modifed ${LOCK_PATH}
	else
		echo Installing ${PKG_DIR} packages
	fi
	if [ -e "${PKG_DIR}/.meteor" ]; then
		# Due to binary compilation differences, meteor projects need to use it's exact node version
		PATH=$(dirname $(meteor node -e "process.stdout.write(process.execPath)")):$PATH yarn --cwd "${PKG_DIR}"
	else
		yarn --cwd "${PKG_DIR}"
	fi
done
