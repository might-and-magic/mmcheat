#!/bin/sh
# Build the MMCheat release package.
#
#   ./build.sh                 build/ and dist/MMCheat-<version>.zip
#   ./build.sh --no-zip        only the build/ folder
#   ./build.sh --version       print the version from about.lua and exit
#   ./build.sh --fetch-binaries  (re-)download the bundled binaries and exit
#
# The two bundled binaries (ExeMods/iup.dll and vcruntime140.dll) are not kept
# in this repository; they are downloaded from the "binaries" release when they
# are missing. See DEVELOPMENT.md.
set -eu

cd "$(dirname "$0")"
. tools/lib.sh

ABOUT="Scripts/Modules/MMCheat/about.lua"
BUILD_DIR="build"
DIST_DIR="dist"
BINARIES_TAG="${MMCHEAT_BINARIES_TAG:-binaries}"
BINARIES_URL="${MMCHEAT_BINARIES_URL:-https://github.com/might-and-magic/mmcheat/releases/download/$BINARIES_TAG}"

# Files that are generated at runtime by MMCheat and must not be packaged
RUNTIME_FILES="conf.ini coords.txt"

make_zip_wanted=1
fetch_only=0

while [ $# -gt 0 ]; do
	case "$1" in
	--no-zip) make_zip_wanted=0 ;;
	--fetch-binaries) fetch_only=1 ;;
	--version)
		mmcheat_version "$ABOUT"
		exit 0
		;;
	-h | --help)
		cat <<'EOF'
Build the MMCheat release package.

  build.sh                    build/ and dist/MMCheat-<version>.zip
  build.sh --no-zip           only the build/ folder
  build.sh --version          print the version from about.lua
  build.sh --fetch-binaries   (re-)download the bundled binaries

The two bundled binaries (ExeMods/iup.dll and vcruntime140.dll) are not kept
in this repository; they are downloaded from the "binaries" release when they
are missing. See DEVELOPMENT.md.

On Windows run build.ps1 with the same arguments.
EOF
		exit 0
		;;
	*) die "unknown option: $1 (try --help)" ;;
	esac
	shift
done

# fetch_binary RELATIVE_PATH ASSET_NAME
fetch_binary() {
	mkdir -p "$(dirname "$1")"
	info "downloading $2 from the $BINARIES_TAG release..."
	download "$BINARIES_URL/$2" "$1"
}

ensure_binaries() {
	_force="${1:-0}"
	if [ "$_force" = 1 ] || [ ! -f "ExeMods/iup.dll" ]; then
		fetch_binary "ExeMods/iup.dll" "iup.dll"
	fi
	if [ "$_force" = 1 ] || [ ! -f "vcruntime140.dll" ]; then
		fetch_binary "vcruntime140.dll" "vcruntime140.dll"
	fi
}

if [ "$fetch_only" = 1 ]; then
	ensure_binaries 1
	info "binaries are in place"
	exit 0
fi

version="$(mmcheat_version "$ABOUT")"
[ -n "$version" ] || die "cannot read the version from $ABOUT"

ensure_binaries

info "building MMCheat $version"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/ExeMods" "$BUILD_DIR/Scripts/General" "$BUILD_DIR/Scripts/Modules"

cp "ExeMods/iup.dll" "$BUILD_DIR/ExeMods/"
cp "vcruntime140.dll" "$BUILD_DIR/"
cp "Scripts/General/MMCheat.lua" "$BUILD_DIR/Scripts/General/"
cp "Scripts/Modules/iup.lua" "$BUILD_DIR/Scripts/Modules/"
cp -R "Scripts/Modules/MMCheat" "$BUILD_DIR/Scripts/Modules/"

for f in $RUNTIME_FILES; do
	rm -f "$BUILD_DIR/Scripts/Modules/MMCheat/$f"
done

files="$(find "$BUILD_DIR" -type f | wc -l | tr -d ' ')"
info "$BUILD_DIR/ ready ($files files)"

if [ "$make_zip_wanted" = 1 ]; then
	zip_path="$DIST_DIR/MMCheat-$version.zip"
	make_zip "$BUILD_DIR" "$zip_path"
	info "$zip_path"
	echo "$zip_path"
fi
