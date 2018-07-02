#!/usr/bin/env bash

YARN_ARGS="--frozen-lockfile --non-interactive --silent"

if [[ ${npm_lifecycle_event} == "postinstall" ]]; then
	if [[ $(basename $(cd .. && pwd)) != "node_modules" ]]; then
		# Don't run as a postinstall script unless installed as a dependency
		exit 0
	fi
	# Capture this before we cd below
	INSTALLED_IN_PKG_DIR=$(cd .. && npm prefix)  # Can't see how else to figure out where is the package.json we're installed into
fi

cd $(git rev-parse --show-toplevel)  # Run everything from the root of the git tree to match what we store in GIT_PATHS

if [[ ${HUSKY_GIT_PARAMS+foo} ]]; then  # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
    # HUSKY_GIT_PARAMS exists therefore called by husky git hook
	HUSKY_GIT_PARAMS=(${HUSKY_GIT_PARAMS})  # Turn into array
	if [[ ${HUSKY_GIT_PARAMS[1]} ]]; then
		# post-checkout hook
		GIT_COMPARE_PATHS=(${HUSKY_GIT_PARAMS[@]:0:2})  # Drop the flag param if any
	else
		# post-merge hook
		GIT_COMPARE_PATHS=(ORIG_HEAD HEAD)
	fi
    SELECTIVE_UPDATE=true
	GIT_PATHS=$(git diff-tree -r --name-only --no-commit-id ${GIT_COMPARE_PATHS[@]})
else
	# Sync everything
	GIT_PATHS=$(git ls-tree --full-tree -r --name-only HEAD)
	if [[ ${npm_lifecycle_event} == "postinstall" ]]; then
		# Don't try and install the package file that we're already in the middle of installing
		SKIP_LOCK_PATH=$(git ls-tree --full-name --name-only HEAD "${INSTALLED_IN_PKG_DIR}/yarn.lock")  # So path is same format that we need to match to
	fi
fi

echo "${GIT_PATHS}" | grep "\(^\|/\)yarn.lock$" | while read -r LOCK_PATH; do
	if [[ ${LOCK_PATH} == ${SKIP_LOCK_PATH} ]]; then
		continue
	fi
	PKG_DIR=$(dirname ${LOCK_PATH})
	if [[ ${SELECTIVE_UPDATE} ]]; then
		echo Updating dependencies due to modifed ${LOCK_PATH}
	else
		if [[ ${PKG_DIR} == "." ]]; then
			echo Installing root packages
		else
			echo Installing ${PKG_DIR} packages
		fi
	fi
	if [ -e "${PKG_DIR}/.meteor" ]; then
		# Due to binary compilation differences, meteor projects need to use its exact node version
		METEOR_NODE=$(cd ${PKG_DIR} && meteor node -e "process.stdout.write(process.execPath)")
		PATH=$(dirname ${METEOR_NODE}):$PATH yarn install --cwd "${PKG_DIR}" ${YARN_ARGS}
	else
		yarn install --cwd "${PKG_DIR}" ${YARN_ARGS}
	fi
done
