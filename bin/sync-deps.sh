#!/usr/bin/env bash

INSTALL_ARGS="--frozen-lockfile --non-interactive --silent --ignore-engines"

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
    # Sync modified files
    SELECTIVE_UPDATE=1
	GIT_PATHS=$(git diff-tree -r --name-only --no-commit-id ${GIT_COMPARE_PATHS[@]})
else
	# Sync all files
	GIT_PATHS=$(git ls-tree --full-tree -r --name-only HEAD)
fi

echo "${GIT_PATHS}" | grep "\(^\|/\)yarn.lock$" | while read -r LOCK_PATH; do
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
	if [[ -e "${PKG_DIR}/.meteor" ]]; then
		# Due to binary compilation differences, meteor projects need to use its exact node version
		METEOR_NODE=$(cd ${PKG_DIR} && meteor node -e "process.stdout.write(process.execPath)")
		PATH=$(dirname ${METEOR_NODE}):$PATH SYNCING_DEPS=1 yarn install --cwd "${PKG_DIR}" ${INSTALL_ARGS}
	else
		SYNCING_DEPS=1 yarn install --cwd "${PKG_DIR}" ${INSTALL_ARGS}
	fi
done
