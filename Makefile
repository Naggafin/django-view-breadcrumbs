# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

.DEFAULT_GOAL := help

PYTHON	:= /usr/bin/env python3
MANAGE_PY   := $(PYTHON) manage.py
PYTHON_PIP  := /usr/bin/env pip3
PIP_COMPILE := /usr/bin/env pip-compile

# Put it first so that "make" without argument is like "make help".
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-32s-\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: help

guard-%: ## Checks that env var is set else exits with non 0 mainly used in CI;
	@if [ -z '${${*}}' ]; then echo 'Environment variable $* not set' && exit 1; fi

# --------------------------------------------------------
# ------- Python package (pip) management commands -------
# --------------------------------------------------------

clean-build: ## Clean project build artifacts.
	@echo "Removing build assets..."
	@$(PYTHON) setup.py clean
	@rm -rf build/
	@rm -rf dist/
	@rm -rf *.egg-info

install: clean-build  ## Install project dependencies.
	@echo "Installing project in dependencies..."
	@$(PYTHON_PIP) install -r requirements.txt

install-lint: pipconf clean-build  ## Install lint extra dependencies.
	@echo "Installing lint extra requirements..."
	@$(PYTHON_PIP) install -e .'[lint]'

install-test: clean-build  ## Install test extra dependencies.
	@echo "Installing test extra requirements..."
	@$(PYTHON_PIP) install -e .'[test]'

install-dev: clean-build  ## Install development extra dependencies.
	@echo "Installing development requirements..."
	@$(PYTHON_PIP) install -e .'[development]' -r requirements.txt

update-requirements:  ## Updates the requirement.txt adding missing package dependencies
	@echo "Syncing the package requirements.txt..."
	@$(PIP_COMPILE)

release-to-pypi: clean-build ## Release project to pypi
	@$(PYTHON_PIP) install -U twine pypandoc
	@$(PYTHON) setup.py sdist bdist_wheel
	@twine upload dist/*

# ----------------------------------------------------------
# ---------- Upgrade project version (bumpversion)  --------
# ----------------------------------------------------------
increase-version: clean-build  ## Bump the project version (using the $PART env: defaults to 'patch').
	@echo "Increasing project '$(PART)' version..."
	@$(PYTHON_PIP) install -q -e .'[deploy]'
	@bumpversion --verbose $(PART)

# ----------------------------------------------------------
# --------- Run project Test -------------------------------
# ----------------------------------------------------------
tox: install-test
	@tox

clean-test-all: clean-build
	@rm -rf .tox/
	@rm -rf .pytest_cache/
	@rm test.db
