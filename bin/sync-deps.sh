#!/usr/bin/env bash

set -e

ROOT_DIR=$(git rev-parse --show-toplevel)

cd "${ROOT_DIR}" # Run everything from the root of the git tree to match what we store in GIT_PATHS

if [[ ${HUSKY_GIT_PARAMS+foo} ]]; then  # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
  # HUSKY_GIT_PARAMS exists therefore called by husky git hook
  read -ra GIT_PARAMS <<< "${HUSKY_GIT_PARAMS}" # Turn into array
  if [[ ${GIT_PARAMS[0]} == "rebase" || ${GIT_PARAMS[0]} == "amend" ]]; then
    # post-rewrite hook, so check everything
    GIT_COMPARE_PATHS=()
  elif [[ ${GIT_PARAMS[1]} ]]; then
    # post-checkout hook
    read -ra GIT_COMPARE_PATHS <<< "${GIT_PARAMS[@]:0:2}"
  else
    # post-merge hook
    GIT_COMPARE_PATHS=(ORIG_HEAD HEAD)
  fi
fi

if [[ "${GIT_COMPARE_PATHS[*]}" ]]; then
  # Find modified files
  GIT_PATHS=$(git diff-tree -r --name-only --no-commit-id "${GIT_COMPARE_PATHS[@]}")
  if [[ ${GIT_PATHS} ]]; then
    SELECTIVE_UPDATE=1
  else
    echo "No git diff-ree paths so syncing all files"
    GIT_PATHS=$(git ls-tree --full-tree -r --name-only HEAD)
  fi
else
  # Sync all files
  GIT_PATHS=$(git ls-tree --full-tree -r --name-only HEAD)
fi

echo "${GIT_PATHS}" | grep "\(^\|/\)pnpm-lock.yaml$" | while read -r LOCK_PATH; do
  if [[ ! -f "${LOCK_PATH}" ]]; then
    continue
  fi
  PKG_DIR=$(dirname "${LOCK_PATH}")
  if [[ ${SELECTIVE_UPDATE} ]]; then
    echo "Updating pnpm dependencies due to modified ${LOCK_PATH}"
  else
    if [[ ${PKG_DIR} == "." ]]; then
      echo "Installing root pnpm packages"
    else
      echo "Installing ${PKG_DIR} pnpm packages"
    fi
  fi
  pnpm install --dir "${PKG_DIR}" --frozen-lockfile --prefer-offline || true
done

echo "${GIT_PATHS}" | grep "\(^\|/\)yarn.lock$" | while read -r LOCK_PATH; do
  if [[ ! -f "${LOCK_PATH}" ]]; then
    continue
  fi
  PKG_DIR=$(dirname "${LOCK_PATH}")
  if [[ ${SELECTIVE_UPDATE} ]]; then
    echo "Updating yarn dependencies due to modified ${LOCK_PATH}"
  else
    if [[ ${PKG_DIR} == "." ]]; then
      echo "Installing root yarn packages"
    else
      echo "Installing ${PKG_DIR} yarn packages"
    fi
  fi
  yarn install --cwd "${PKG_DIR}" --frozen-lockfile --non-interactive --silent --ignore-engines || true
done

echo "${GIT_PATHS}" | grep "\(^\|/\)uv.lock$" | while read -r LOCK_PATH; do
  if [[ ! -f "${LOCK_PATH}" ]]; then
    continue
  fi
  PKG_DIR=$(dirname "${LOCK_PATH}")
  if [[ ${SELECTIVE_UPDATE} ]]; then
    echo "Updating poetry dependencies due to modified ${LOCK_PATH}"
  else
    if [[ ${PKG_DIR} == "." ]]; then
      echo "Installing root python packages"
    else
      echo "Installing ${PKG_DIR} python packages"
    fi
  fi
  uv sync --all-packages --directory "${PKG_DIR}"
done

echo "${GIT_PATHS}" | grep "\(^\|/\)poetry.lock$" | while read -r LOCK_PATH; do
  if [[ ! -f "${LOCK_PATH}" ]]; then
    continue
  fi
  PKG_DIR=$(dirname "${LOCK_PATH}")
  if [[ ${SELECTIVE_UPDATE} ]]; then
    echo "Updating poetry dependencies due to modified ${LOCK_PATH}"
  else
    if [[ ${PKG_DIR} == "." ]]; then
      echo "Installing root poetry packages"
    else
      echo "Installing ${PKG_DIR} poetry packages"
    fi
  fi
  PYPROJECT_PATH=${LOCK_PATH//poetry.lock/pyproject.toml}
  PY_SHORT_VERSION=$(grep -E "^python\s*=\s*[\"'][~^>=]*[0-9]\.[0-9]+.*[\"']\s*$" "${PYPROJECT_PATH}" | grep -E -o "[0-9]\.[0-9]+")
  pyenv install --skip-existing "${PY_SHORT_VERSION}"
  (POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true POETRY_VIRTUALENVS_IN_PROJECT=true PATH=$(pyenv prefix "${PY_SHORT_VERSION}")/bin:${PATH} \
    poetry sync -C "${PKG_DIR}" --compile --no-interaction || true)
done

echo "${GIT_PATHS}" | grep "\(^\|/\)Pipfile.lock$" | while read -r LOCK_PATH; do
  if [[ ! -f "${LOCK_PATH}" ]]; then
    continue
  fi
  PKG_DIR=$(dirname "${LOCK_PATH}")
  if [[ ${SELECTIVE_UPDATE} ]]; then
    echo "Updating pipenv dependencies due to modified ${LOCK_PATH}"
  else
    if [[ ${PKG_DIR} == "." ]]; then
      echo "Installing root pipenv packages"
    else
      echo "Installing ${PKG_DIR} pipenv packages"
    fi
  fi
  PIPFILE_PATH=${LOCK_PATH//Pipfile.lock/Pipfile}
  PY_SHORT_VERSION=$(grep python_version "${PIPFILE_PATH}" | grep -o "[0-9.]\+")
  if [[ -z "${SKIP_PYENV_INSTALL}" ]]; then
    PY_LATEST_VERSION=$(pyenv latest -k "${PY_SHORT_VERSION}")
    pyenv install --skip-existing "${PY_LATEST_VERSION}"
    PYENV_PYTHON="$(pyenv prefix "${PY_LATEST_VERSION}")/bin/python"
  else
    PYENV_PYTHON="$(pyenv prefix "${PY_SHORT_VERSION}")/bin/python"
  fi
  PYENV_PY_VERSION_OUTPUT=$("${PYENV_PYTHON}" --version)
  VENV_PY_VERSION_OUTPUT=$(cd "${PKG_DIR}" && "$(pipenv --py)" --version || echo "no venv")
  VENV_DIR="${PKG_DIR}/.venv"
  if [[ "${PYENV_PY_VERSION_OUTPUT}" == "${VENV_PY_VERSION_OUTPUT}" ]]; then
    (cd "${PKG_DIR}" && (PIPENV_VENV_IN_PROJECT=1 PIPENV_IGNORE_VIRTUALENVS=1 pipenv sync --dev || true))
  else
    if [[ -d ${VENV_DIR} ]]; then
      echo "Removing ${VENV_DIR} due to python version change ${VENV_PY_VERSION_OUTPUT} -> ${PYENV_PY_VERSION_OUTPUT}"
      rm -rf "${VENV_DIR}"
    fi
    (cd "${PKG_DIR}" && (PIPENV_VENV_IN_PROJECT=1 PIPENV_IGNORE_VIRTUALENVS=1 pipenv install --dev --deploy --python "${PYENV_PYTHON}" || true))
  fi
done
