# shellcheck shell=sh
# Shared helpers for MMCheat's build and packaging scripts.
# POSIX sh, no bashisms. Sourced by build.sh and tools/mmextension.sh.

die() {
	echo "error: $*" >&2
	exit 1
}

info() {
	echo "$*" >&2
}

# download URL FILE
# Downloads to FILE using whatever HTTP client is available.
download() {
	_url="$1"
	_out="$2"
	if command -v curl >/dev/null 2>&1; then
		curl -fSL --retry 3 -o "$_out" "$_url" || die "download failed: $_url"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$_out" "$_url" || die "download failed: $_url"
	else
		die "neither curl nor wget is available to download $_url"
	fi
}

# to_native_path PATH
# Converts a POSIX path to a Windows path when running under Git Bash/MSYS,
# so that native tools (PowerShell) understand it.
to_native_path() {
	if command -v cygpath >/dev/null 2>&1; then
		cygpath -w "$1"
	else
		echo "$1"
	fi
}

# make_zip SOURCE_DIR ZIP_PATH
# Zips the *contents* of SOURCE_DIR (so the archive has no extra top folder).
# Tries every tool that might be installed and only fails if none worked.
make_zip() {
	_src="$1"
	_zip="$2"

	rm -f "$_zip"
	mkdir -p "$(dirname "$_zip")"

	# absolute path: the zip tools below run with SOURCE_DIR as working directory
	case "$_zip" in
	/* | ?:[/\\]*) _abszip="$_zip" ;;
	*) _abszip="$(pwd)/$_zip" ;;
	esac

	if command -v zip >/dev/null 2>&1; then
		(cd "$_src" && zip -qr "$_abszip" .) && return 0
		info "zip failed, trying another tool"
	fi

	if command -v 7z >/dev/null 2>&1; then
		(cd "$_src" && 7z a -tzip -bso0 -bsp0 "$_abszip" ./*) && return 0
		info "7z failed, trying another tool"
	fi

	# Windows: tools/zip.ps1 (relative to the repository root, which the calling
	# scripts make the working directory)
	if command -v powershell >/dev/null 2>&1 && [ -f tools/zip.ps1 ]; then
		powershell -NoProfile -ExecutionPolicy Bypass -File "$(to_native_path tools/zip.ps1)" \
			-Source "$(to_native_path "$_src")" -Destination "$(to_native_path "$_abszip")" &&
			return 0
		info "powershell zip failed"
	fi

	die "no working zip tool found (install zip or 7z, or run on Windows where PowerShell is used)"
}

# find_gh
# Prints a usable GitHub CLI command, or nothing. On Windows it is often not on
# the PATH of a shell that was started before it was installed.
find_gh() {
	if command -v gh >/dev/null 2>&1; then
		echo gh
		return 0
	fi
	for _p in "/c/Program Files/GitHub CLI/gh.exe" "/c/Program Files (x86)/GitHub CLI/gh.exe"; do
		if [ -x "$_p" ]; then
			echo "$_p"
			return 0
		fi
	done
	return 1
}

# mmcheat_version ABOUT_LUA_PATH
# Prints the version string from Scripts/Modules/MMCheat/about.lua.
mmcheat_version() {
	sed -n 's/^[[:space:]]*version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}
