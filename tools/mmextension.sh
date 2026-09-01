#!/bin/sh
# Check for and package MMExtension snapshots for MMCheat users.
#
#   tools/mmextension.sh check                 is upstream newer than what we ship?
#   tools/mmextension.sh fetch                 package upstream HEAD
#   tools/mmextension.sh fetch --commit SHA    package a specific commit
#   tools/mmextension.sh fetch --update-env    also record the new snapshot
#
# MMExtension has no releases: it is distributed as the contents of its git
# repository. MMCheat ships a subset of it (see PACKAGING below) named
# MMExtension-<version>-<commit date>.zip, so that users can install a known
# good MMExtension without cloning a repository.
#
# PACKAGING - what goes into the zip, exactly as in the hand-made
# MMExtension-2.3-20250115.zip that MMCheat has shipped so far:
#
#   ExeMods/**            except MMExtension/MMEditorDlg.dll (map editor only)
#   Scripts/**            except .gitignore, the map editor scripts
#                         (Global/Editor *.lua, Global/Convert Blv.lua),
#                         Help/** and Include/** (documentation generation and
#                         developer helpers) and Modules/Build Files List.lua
#   Misc/KillObsolete/Scripts/**  merged into Scripts/ - small scripts that
#                         disable obsolete files of older MMExtension versions
#
# Only git is required (no GitHub API, no jq): the commit and its date are read
# from a shallow clone.
set -eu

cd "$(dirname "$0")/.."
. tools/lib.sh

ENV_FILE="tools/mmextension.env"
DIST_DIR="dist"

[ -f "$ENV_FILE" ] || die "$ENV_FILE not found"
# shellcheck disable=SC1090
. "./$ENV_FILE"

command -v git >/dev/null 2>&1 || die "git is required"

usage() {
	sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
	exit "${1:-0}"
}

upstream_head() {
	git ls-remote "$MMEXT_REPO" "refs/heads/$MMEXT_BRANCH" | awk '{print $1}' | head -n 1
}

cmd_check() {
	_head="$(upstream_head)"
	[ -n "$_head" ] || die "cannot read $MMEXT_BRANCH of $MMEXT_REPO"
	echo "MMEXT_RECORDED_COMMIT=$MMEXT_COMMIT"
	echo "MMEXT_RECORDED_DATE=$MMEXT_DATE"
	echo "MMEXT_UPSTREAM_COMMIT=$_head"
	if [ "$_head" = "$MMEXT_COMMIT" ]; then
		echo "MMEXT_STATUS=up-to-date"
	else
		echo "MMEXT_STATUS=outdated"
	fi
}

# clone_upstream TARGET_DIR REF
clone_upstream() {
	_dir="$1"
	_ref="$2"
	git init -q "$_dir"
	git -C "$_dir" remote add origin "$MMEXT_REPO"
	# GitHub allows fetching a reachable commit directly, so this works for both
	# a branch name and a full commit sha
	git -C "$_dir" fetch -q --depth 1 origin "$_ref" ||
		die "cannot fetch $_ref from $MMEXT_REPO"
	git -C "$_dir" checkout -q FETCH_HEAD
}

# read_version SOURCE_DIR
# MMExtension has no version file; the authoritative version is the FILEVERSION
# resource of the DLL that upstream bumps on a release
# ("FILEVERSION 2,3,0,0" -> 2.3, "FILEVERSION 2,4,1,0" -> 2.4.1).
read_version() {
	_rc="$1/Src/MMExtension/MMExtension.rc"
	[ -f "$_rc" ] || return 1
	_nums="$(sed -n 's/^[[:space:]]*FILEVERSION[[:space:]]*\([0-9,[:space:]]*\).*/\1/p' "$_rc" |
		head -n 1 | tr -d '[:space:]')"
	[ -n "$_nums" ] || return 1
	_major="$(echo "$_nums" | cut -d, -f1)"
	_minor="$(echo "$_nums" | cut -d, -f2)"
	_patch="$(echo "$_nums" | cut -d, -f3)"
	[ -n "$_major" ] && [ -n "$_minor" ] || return 1
	if [ -n "$_patch" ] && [ "$_patch" != "0" ]; then
		echo "$_major.$_minor.$_patch"
	else
		echo "$_major.$_minor"
	fi
}

# stage_package SOURCE_DIR STAGE_DIR
stage_package() {
	_src="$1"
	_stage="$2"

	mkdir -p "$_stage"
	cp -R "$_src/ExeMods" "$_stage/"
	cp -R "$_src/Scripts" "$_stage/"

	# map editor components: not useful for MMCheat users, and MMEditorDlg.dll
	# alone is bigger than the rest of the package
	rm -f "$_stage/ExeMods/MMExtension/MMEditorDlg.dll"
	rm -f "$_stage/Scripts/Global/Convert Blv.lua"
	rm -f "$_stage/Scripts/Global/Editor "*.lua
	# documentation generation and developer helpers
	rm -rf "$_stage/Scripts/Help" "$_stage/Scripts/Include"
	rm -f "$_stage/Scripts/Modules/Build Files List.lua"
	# repository housekeeping
	rm -f "$_stage/Scripts/.gitignore"

	# scripts that neutralize obsolete files of older MMExtension versions
	if [ -d "$_src/Misc/KillObsolete/Scripts" ]; then
		cp -R "$_src/Misc/KillObsolete/Scripts/." "$_stage/Scripts/"
	fi
}

cmd_fetch() {
	_ref="$MMEXT_BRANCH"
	_update_env=0
	while [ $# -gt 0 ]; do
		case "$1" in
		--commit)
			shift
			[ $# -gt 0 ] || die "--commit needs a value"
			_ref="$1"
			;;
		--update-env) _update_env=1 ;;
		*) die "unknown option: $1" ;;
		esac
		shift
	done

	_tmp="$(mktemp -d)"
	# shellcheck disable=SC2064
	trap "rm -rf '$_tmp'" EXIT INT TERM

	info "fetching $_ref from $MMEXT_REPO ..."
	clone_upstream "$_tmp/src" "$_ref"

	_commit="$(git -C "$_tmp/src" rev-parse HEAD)"
	# UTC, so the name of the zip does not depend on the machine's timezone
	_date="$(TZ=UTC0 git -C "$_tmp/src" log -1 --format=%cd --date=format-local:%Y%m%d HEAD)"
	_version="$(read_version "$_tmp/src" || true)"
	if [ -z "$_version" ]; then
		info "warning: cannot read the version from upstream, keeping $MMEXT_VERSION"
		_version="$MMEXT_VERSION"
	fi

	stage_package "$_tmp/src" "$_tmp/stage"
	_files="$(find "$_tmp/stage" -type f | wc -l | tr -d ' ')"

	_zip="$DIST_DIR/MMExtension-$_version-$_date.zip"
	make_zip "$_tmp/stage" "$_zip"
	info "$_zip ($_files files, version $_version, commit $_commit)"

	if [ "$_update_env" = 1 ]; then
		sed -e "s/^MMEXT_VERSION=.*/MMEXT_VERSION=$_version/" \
			-e "s/^MMEXT_DATE=.*/MMEXT_DATE=$_date/" \
			-e "s/^MMEXT_COMMIT=.*/MMEXT_COMMIT=$_commit/" \
			"$ENV_FILE" >"$ENV_FILE.tmp"
		mv "$ENV_FILE.tmp" "$ENV_FILE"
		info "$ENV_FILE updated"
	fi

	echo "MMEXT_VERSION=$_version"
	echo "MMEXT_COMMIT=$_commit"
	echo "MMEXT_DATE=$_date"
	echo "MMEXT_FILES=$_files"
	echo "MMEXT_ZIP=$_zip"
}

[ $# -gt 0 ] || usage 1
cmd="$1"
shift
case "$cmd" in
check) cmd_check "$@" ;;
fetch) cmd_fetch "$@" ;;
-h | --help | help) usage ;;
*) die "unknown command: $cmd (try --help)" ;;
esac
