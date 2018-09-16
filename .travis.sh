#!/bin/bash

# Exit, if one command fails
set -e

# Deploy documentation to GitHub pages
if [ "$TRAVIS_BRANCH" == "master" -a "$TRAVIS_PULL_REQUEST" == "false" ]; then
  REMOTE="https://${GH_TOKEN}@github.com/squidfunk/mkdocs-material"

  # Set configuration for repository and deploy documentation
  git config --global user.name "${GH_NAME}"
  git config --global user.email "${GH_EMAIL}"
  git remote set-url origin ${REMOTE}

  # Install Material, so we can use it as a base template and add overrides
  python setup.py install

  # # Override theme configuration
  # sed -i 's/name: null/name: material/g' mkdocs.yml
  # sed -i 's/custom_dir: material/custom_dir: overrides/g' mkdocs.yml

  # Build documentation with overrides and publish to GitHub pages
  mkdocs gh-deploy --force
  mkdocs --version
fi

# Remove overrides directory so it won't get included in the image
# rm -rf overrides

# Terminate if we're not on a release branch
echo "${TRAVIS_BRANCH}" | grep -qvE "^[0-9.]+$" && exit 0; :;

# Install dependencies for release build
pip install wheel twine

# Build and install theme and Docker image
python setup.py build sdist bdist_wheel --universal
docker build -t ${TRAVIS_REPO_SLUG} .

# Test Docker image build
docker run --rm -it -v $(pwd):/docs ${TRAVIS_REPO_SLUG} build --theme material

# Push release to PyPI
twine upload -u ${PYPI_USERNAME} -p ${PYPI_PASSWORD} dist/*

# Push image to Docker Hub
docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
docker tag ${TRAVIS_REPO_SLUG} ${TRAVIS_REPO_SLUG}:${TRAVIS_BRANCH}
docker tag ${TRAVIS_REPO_SLUG} ${TRAVIS_REPO_SLUG}:latest
docker push ${TRAVIS_REPO_SLUG}
