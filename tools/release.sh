#!/bin/sh
# Release a new MMCheat version.
#
#   tools/release.sh 1.2.0
#   tools/release.sh 1.2.0 --dry-run          show what would happen
#   tools/release.sh 1.2.0 --skip-mmextension leave the MMExtension snapshot alone
#
# The order is the point of this script:
#
#   1. refuse to run unless main is clean and in sync with the remote
#   2. MMExtension first: if upstream moved on, package the new snapshot,
#      publish it to the "mmextension" release and record it in
#      tools/mmextension.env
#   3. update README.md so its download links point at the MMExtension
#      snapshot from step 2 and at the MMCheat version about to be released
#   4. write the new version and date into about.lua
#   5. commit, tag and push - the Release workflow builds MMCheat and
#      publishes it under that tag
set -eu

cd "$(dirname "$0")/.."
. tools/lib.sh

ABOUT="Scripts/Modules/MMCheat/about.lua"
README="README.md"
ENV_FILE="tools/mmextension.env"
SNAPSHOT_TAG="mmextension"
REPO_URL="https://github.com/might-and-magic/mmcheat"
BRANCH="main"

version=""
dry_run=0
skip_mmext=0

while [ $# -gt 0 ]; do
	case "$1" in
	--dry-run) dry_run=1 ;;
	--skip-mmextension) skip_mmext=1 ;;
	-h | --help)
		cat <<'EOF'
Release a new MMCheat version.

  release.sh 1.2.0
  release.sh 1.2.0 --dry-run             show what would happen
  release.sh 1.2.0 --skip-mmextension    leave the MMExtension snapshot alone

Publishes a fresh MMExtension snapshot when upstream moved on, points the
README download links at it and at the new MMCheat version, bumps about.lua,
then commits, tags and pushes. The Release workflow builds and publishes
MMCheat from the tag.

On Windows run tools\release.ps1 with the same arguments.
EOF
		exit 0
		;;
	-*) die "unknown option: $1 (try --help)" ;;
	*)
		[ -z "$version" ] || die "give exactly one version"
		version="$1"
		;;
	esac
	shift
done

[ -n "$version" ] || die "usage: release.sh <version> (try --help)"
echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' ||
	die "version must look like 1.2.0, got: $version"

run() {
	if [ "$dry_run" = 1 ]; then
		echo "would run: $*" >&2
	else
		"$@"
	fi
}

# edit_file FILE SED_EXPR...
edit_file() {
	_file="$1"
	shift
	if [ "$dry_run" = 1 ]; then
		echo "would edit $_file" >&2
		return 0
	fi
	sed "$@" "$_file" >"$_file.tmp"
	mv "$_file.tmp" "$_file"
}

# ---------------------------------------------------------------- 1. checks
info "== checking the working tree"

[ "$(git rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || die "not on $BRANCH"
if ! git diff --quiet || ! git diff --cached --quiet; then
	die "the working tree has uncommitted changes"
fi
git fetch -q origin "$BRANCH"
[ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$BRANCH")" ] ||
	die "$BRANCH and origin/$BRANCH have diverged, pull or push first"
if git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
	die "tag v$version already exists"
fi

info "   version $(mmcheat_version "$ABOUT") -> $version"

# ------------------------------------------------- 2. MMExtension snapshot
if [ "$skip_mmext" = 1 ]; then
	info "== skipping the MMExtension snapshot"
else
	info "== checking the MMExtension snapshot"
	if [ "$(tools/mmextension.sh check | sed -n 's/^MMEXT_STATUS=//p')" = "up-to-date" ]; then
		info "   already the current one"
	else
		gh="$(find_gh || true)"
		[ -n "$gh" ] || die "upstream MMExtension moved on but the GitHub CLI is
missing, so the new snapshot cannot be published. Install it, or re-run with
--skip-mmextension to release MMCheat without refreshing the snapshot."

		info "   upstream moved on, packaging it"
		zip="$(tools/mmextension.sh fetch --update-env | sed -n 's/^MMEXT_ZIP=//p')"
		[ -f "$zip" ] || die "the snapshot was not written"

		info "   publishing $zip"
		run "$gh" release upload "$SNAPSHOT_TAG" "$zip" --clobber
		run git add "$ENV_FILE"
	fi
fi

# ------------------------------------------------------------- 3. changelog
# the release notes link to README.md#v<version>, so the section has to exist
info "== checking the changelog entry for $version"
grep -q "<a id=\"v$version\"></a>" "$README" ||
	die "$README has no changelog entry for $version. Add one under
\"## Changelog\", starting with:

  ### <a id=\"v$version\"></a>[$version]($REPO_URL/releases/tag/v$version) ($(TZ=UTC0 date +%Y-%m-%d))

The GitHub release notes link to that anchor."

# ---------------------------------------------------------------- 4. README
# shellcheck disable=SC1090
. "./$ENV_FILE"
mmext_zip="MMExtension-$MMEXT_VERSION-$MMEXT_DATE.zip"

info "== pointing the README download links at"
info "   $mmext_zip"
info "   MMCheat-$version.zip"

edit_file "$README" \
	-e "s|$REPO_URL/releases/download/$SNAPSHOT_TAG/MMExtension-[0-9.]*-[0-9]*\.zip|$REPO_URL/releases/download/$SNAPSHOT_TAG/$mmext_zip|g" \
	-e "s|$REPO_URL/releases/download/v[0-9.]*/MMCheat-[0-9.]*\.zip|$REPO_URL/releases/download/v$version/MMCheat-$version.zip|g"

if [ "$dry_run" = 0 ]; then
	grep -q "releases/download/$SNAPSHOT_TAG/$mmext_zip" "$README" ||
		die "the MMExtension link in $README was not updated"
	grep -q "releases/download/v$version/MMCheat-$version.zip" "$README" ||
		die "the MMCheat link in $README was not updated"
fi

# -------------------------------------------------------------- 5. version
info "== writing version $version into $ABOUT"
edit_file "$ABOUT" \
	-e "s/^\([[:space:]]*version[[:space:]]*=[[:space:]]*\)\"[^\"]*\"/\1\"$version\"/" \
	-e "s/^\([[:space:]]*version_date[[:space:]]*=[[:space:]]*\)\"[^\"]*\"/\1\"$(TZ=UTC0 date +%Y-%m-%d)\"/"

if [ "$dry_run" = 0 ]; then
	[ "$(mmcheat_version "$ABOUT")" = "$version" ] || die "failed to write the version"
fi

# --------------------------------------------------------- 6. commit & push
info "== committing, tagging and pushing"
run git add "$ABOUT" "$README"
run git commit -m "MMCheat $version"
run git tag "v$version"
run git push origin "$BRANCH"
run git push origin "v$version"

info ""
info "pushed v$version - the Release workflow builds and publishes it:"
info "  $REPO_URL/actions"
