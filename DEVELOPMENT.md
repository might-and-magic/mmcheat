# MMCheat development

Notes for working on MMCheat itself. For using it, see [README.md](README.md).

## What this repository is

MMCheat is a set of Lua scripts that live **inside a Might and Magic game
folder**, so this repository is meant to be checked out into such a folder: its
paths (`Scripts/General/`, `Scripts/Modules/`, `ExeMods/`) are the game's own
paths, and `.gitignore` ignores everything except the files that belong to
MMCheat.

| path | what it is |
| --- | --- |
| `Scripts/General/MMCheat.lua` | entry point loaded by MMExtension, binds <kbd>Ctrl</kbd>+<kbd>Backspace</kbd> |
| `Scripts/Modules/MMCheat/` | all of MMCheat (UI, utilities, i18n, data) |
| `Scripts/Modules/iup.lua` | LuaJIT FFI binding for the IUP GUI toolkit |
| `ExeMods/iup.dll` | IUP 3.32, not in git (see [Bundled binaries](#bundled-binaries)) |
| `vcruntime140.dll` | VC++ runtime needed by IUP, not in git |
| `build.sh` | builds the release package (`build.ps1` is a Windows wrapper for it) |
| `tools/` | packaging helpers and in-game test scripts |

## Setting up a development install

1. Install a game MMCheat supports:
   - **MMMerge** (latest, includes MMExtension 2.3), or
   - **MM6, MM7 or MM8** + the [GrayFace patch](https://grayface.github.io/mm/)
     + [MMExtension 2.3](https://github.com/GrayFace/MMExtension)
     (the MMExtension zip linked from README.md is a packaged snapshot of that
     repository, see [MMExtension snapshots](#mmextension-snapshots)).

2. Turn the game folder into a working tree of this repository. Cloning into a
   non-empty folder is not possible, so fetch into it instead:

   ```sh
   cd "<game folder>"
   git init
   git remote add origin https://github.com/might-and-magic/mmcheat.git
   git fetch origin
   git checkout -t origin/main
   ```

   Everything that is not MMCheat stays untracked: `.gitignore` ignores the
   whole folder and then re-includes only MMCheat's files.

3. Add the two binaries that are not kept in git:

   ```sh
   ./build.sh --fetch-binaries      # or: .\build.ps1 --fetch-binaries
   ```

   They can also be downloaded by hand from the `binaries` release into
   `ExeMods\iup.dll` and `vcruntime140.dll` (game folder root).

4. Start the game and press <kbd>Ctrl</kbd>+<kbd>Backspace</kbd>. Lua files are
   read when MMCheat opens, so most changes only need the dialog to be
   reopened; changes to `Scripts/General/MMCheat.lua` need a game restart.

## Building

```sh
./build.sh          # Linux, macOS, Git Bash - also what CI uses
.\build.ps1         # Windows, same flags: it runs build.sh
```

It assembles `build/` and writes `dist/MMCheat-<version>.zip`, whose layout is
what users extract into their game folder. `--no-zip` stops after `build/`;
`--version` prints the version from `about.lua`.

Every `.ps1` here (`build.ps1`, `tools/mmextension.ps1`, `tools/release.ps1`)
is a wrapper around the shell script of the same name, not a port: what goes
into a package, and in which order a release happens, would otherwise be
written down twice and drift apart. They use the bash that comes with Git for
Windows, which any clone of this repository implies.

Zipping needs `zip`, `7z`, or PowerShell — the last is picked automatically on
Windows through `tools/zip.ps1`, which writes standard forward-slash entry
names (`ZipFile::CreateFromDirectory` would use backslashes).

## Releasing

One command, from a clean `main`:

```sh
tools/release.sh 1.2.3          # .\tools\release.ps1 1.2.3 on Windows
tools/release.sh 1.2.3 --dry-run
```

It does the steps of a release in the order they depend on each other:

1. **Check.** Refuses to run unless you are on `main`, the working tree is
   clean and in sync with the remote, and `v1.2.3` does not exist yet.
2. **MMExtension first.** If upstream moved on, the new snapshot is packaged,
   uploaded to the `mmextension` release and recorded in
   `tools/mmextension.env`. It has to happen first, because the next step
   writes its file name into the README. `--skip-mmextension` leaves the
   published snapshot as it is.
3. **Changelog.** Refuses to go on unless README.md's *Changelog* section has
   an entry for the new version, that is a heading carrying the anchor
   `<a id="v1.2.3"></a>`. Write it before releasing: the GitHub release notes
   link to that anchor.
4. **README.** Points both download links at the snapshot from step 2 and at
   the MMCheat version about to be released, and verifies afterwards that both
   links were really rewritten.
5. **Version.** Writes `version` and today's `version_date` into
   `Scripts/Modules/MMCheat/about.lua`.
6. **Push.** Commits everything as `MMCheat 1.2.3`, tags `v1.2.3` and pushes.
   `.github/workflows/release.yml` then verifies that the tag matches
   `about.lua`, downloads the bundled binaries, builds and creates the GitHub
   release with `MMCheat-1.2.3.zip` attached — the file the README now links
   to. The release notes it writes start with a link to
   `README.md#v1.2.3`, the changelog entry from step 3, followed by GitHub's
   generated notes.

Because the README links carry versions, the order above is not a checklist to
remember: the script enforces it, and `--dry-run` shows what it would do.

The `binaries` and `mmextension` releases are file stores rather than versions
of MMCheat, so they stay marked as pre-releases and never appear as the
repository's latest release.

## Bundled binaries

`ExeMods/iup.dll` (IUP 3.32) and `vcruntime140.dll` (the VC++ runtime IUP
needs) are shipped with MMCheat but not kept in git. They live in a dedicated
release tagged `binaries`, which both `build.sh`/`build.ps1` and CI download
from. To create or refresh it:

In the web interface: *Releases* → *Draft a new release* → tag `binaries` →
tick **Set as a pre-release** → attach `ExeMods\iup.dll` and
`vcruntime140.dll` → publish. With the [GitHub CLI](https://cli.github.com):

```sh
gh release create binaries ExeMods/iup.dll vcruntime140.dll \
  --prerelease \
  --title "Bundled binaries" \
  --notes "Third party binaries that MMCheat ships but does not keep in git: IUP 3.32 (GUI toolkit, from https://sourceforge.net/projects/iup/files/) and the Microsoft Visual C++ runtime it needs (x86). Downloaded from here by build.sh / build.ps1 and by the release workflow. This is a file store, not an MMCheat version."
# later updates:
gh release upload binaries ExeMods/iup.dll vcruntime140.dll --clobber
```

Keep it a **pre-release**: otherwise this file store takes the "Latest
release" badge away from the newest MMCheat version.

`MMCHEAT_BINARIES_TAG` / `MMCHEAT_BINARIES_URL` override where they come from.

IUP itself is downloaded from
<https://sourceforge.net/projects/iup/files/> (Windows 32 bit dynamic
libraries); `vcruntime140.dll` is the 32 bit Microsoft redistributable, which
is shipped next to the game executable so users do not have to install it.

## MMExtension snapshots

MMExtension has no releases: it is distributed as the contents of
[its repository](https://github.com/GrayFace/MMExtension). For MM6/7/8 users
MMCheat therefore links to a packaged snapshot of that repository,
`MMExtension-<version>-<commit date>.zip`, built by `tools/mmextension.sh`:

```sh
tools/mmextension.sh check    # is upstream newer than what we ship?
tools/mmextension.sh fetch    # package upstream HEAD into dist/
```

The version comes from upstream's `FILEVERSION` resource and the date from the
commit (UTC), so the name is reproducible. The zip contains `ExeMods/` and
`Scripts/` minus the map editor, documentation generation and developer
helpers, plus `Misc/KillObsolete/Scripts/` merged into `Scripts/` — exactly the
selection of the hand-made `MMExtension-2.3-20250115.zip`; the script
reproduces that package file for file. `tools/mmextension.env` records the
snapshot that is currently shipped.

`.github/workflows/mmextension.yml` checks upstream weekly and opens (or
comments on) an issue with the packaged zip attached to the run. Running that
workflow manually with **publish** enabled uploads the zip to the `mmextension`
release and records it in `tools/mmextension.env`.

## Testing in the game

- `tools/test_blv_ingame.lua` — copy into `Scripts/Global/`, load a save and
  press <kbd>Ctrl</kbd>+<kbd>F9</kbd> to parse the outlines of every indoor map
  and write `mmcheat_blv_test.log`. Delete it from `Scripts/Global/` afterwards.
- Lua errors inside GUI callbacks are caught, shown in a dialog and appended to
  `MMCheatError.log` in the game folder, with a traceback.
- Ask users who report a crash for that file.

### IUP quirks worth knowing

Two workarounds in `Scripts/Modules/MMCheat/ui/main.lua` look odd but are
needed; removing them brings back bugs that are hard to diagnose:

- The dialog is shown fully transparent, re-laid out, re-centered and only then
  revealed. Before the dialog has been shown once, IUP measures the window
  decoration wrongly in the game process and the dialog opens far too tall.
- `EXITLOOP` is set to `NO` before the dialog is torn down. IUP ends its
  message loop by posting `WM_QUIT`; while tearing down the last visible dialog
  it posts another one that no IUP loop consumes, and the game's own message
  loop then receives it and exits — every "apply and close" button appeared to
  crash the game.
