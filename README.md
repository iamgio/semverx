# semverx

`semverx` is a bash script that relies on [semver](https://github.com/fsaintjacques/semver-tool)
to provide additional semver functionalities.

## Installation

```bash
git clone --recurse-submodules https://github.com/iamgio/semverx
ln -s $(pwd)/semverx/semverx.sh /usr/local/bin/semverx
chmod +x /usr/local/bin/semverx
```

## Features

### Bump Git tag

`bump-git-tag` bumps the latest git tag according to semver rules.

```bash
semverx bump-git-tag [major|minor|patch]
```

Example:

```bash
# Current git tag is v1.2.3
semverx bump-git-tag minor # Output: v1.3.0
```

By default, the result is printed to stdout only. You can use `--tag` to automatically create a new tag, and `--push` to push it to the remote.

```bash
semverx bump-git-tag patch --tag --push
```

By default, only tags starting with `v` are considered. You can change this behavior
via `--prefix`. The prefix is removed before bumping and re-added to the output.

```bash
semverx bump-git-tag patch --prefix "" # Consider all tags
```