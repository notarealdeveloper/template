name 	   := $(shell basename $(PWD))
python	   := python
pip    	   := $(python) -m pip
pytest 	   := $(python) -m pytest

##################
### developers ###
##################

install:
	$(pip) install .

develop:
	$(pip) install -e .

check: with-pytest
	$(pytest) -v tests

uninstall:
	$(pip) uninstall --yes $(name)

clean:
	@rm -rf build src/*.egg-info
	@find . -depth -type d -name __pycache__ -exec rm -rf '{}' ';'


##################
### publishing ###
##################

PREFIX	   := $(shell mktemp -d)
PYTHON 	   := $(PREFIX)/bin/python
PIP    	   := $(PYTHON) -m pip
PYTEST 	   := $(PYTHON) -m pytest
MAKE 	   := make PYTHON=$(PYTHON) PREFIX=$(PREFIX)

build: dist-with-build
	$(PYTHON) -m build

install-default:
	$(PIP) install .

install-editable:
	$(PIP) install -e .

install-tarball: build
	$(PIP) install dist/*.tar.gz

install-wheel: build
	$(PIP) install dist/*.whl

pre-build-%:
	$(MAKE) clean
	$(python) -m venv $(PREFIX)
	$(PIP) install --upgrade pip

post-build-%:
	@cowsay "Removing venv at $(PREFIX)"
	@rm -rf $(PREFIX)

pre-builds:
	@rm -rf dist
	@mkdir -p $(PREFIX)

post-builds:
	@cowsay "You may now upload these to pypi:"
	@tree -a dist/

build-%:
	$(MAKE) pre-build-$*
	$(MAKE) build
	$(MAKE) install-$*
	$(MAKE) check
	$(MAKE) post-build-$*

builds:
	$(MAKE) pre-builds
	$(MAKE) build-default
	$(MAKE) build-editable
	$(MAKE) build-tarball
	$(MAKE) build-wheel
	$(MAKE) post-builds

dist:
	$(MAKE) builds
	
	$(MAKE) push-test
	@cowsay "Waiting for the PyPI test servers to update"
	@sleep 10
	$(MAKE) pull-test
	$(MAKE) check
	$(python) -m pip uninstall --yes $(name)
	
	$(MAKE) push-prod
	@cowsay "Waiting for the PyPI servers to update"
	@sleep 10
	$(MAKE) pull-prod
	$(MAKE) check
	@cowsay "Congratulations! You may now be happy!"


###############
### helpers ###
###############

push-test: with-twine
	$(python) -m twine upload --repository testpypi dist/*

pull-test:
	$(pip) install -i https://test.pypi.org/simple/ $(name)

push-prod: with-twine
	$(python) -m twine upload dist/*

pull-prod:
	$(pip) install $(name)

with-%:
	@$(python) -c "import $*" 2>/dev/null || $(pip) install $*
	@true

dist-with-%:
	@$(PYTHON) -c "import $*" 2>/dev/null || $(PIP) install $*
	@true

.PHONY: dist
