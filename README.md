# NextCode

A electron app that idfk has opencode on wich has inf usage if u reset it by clicking a button

uhm

BTW TO MAKE IT WORK U NEED UR WARP MODE SET TO LOCAL PROXY
<img width="741" height="766" alt="image" src="https://github.com/user-attachments/assets/66984d05-9d81-42df-8181-3b69ef0150c1" />


So download the zip file here 

then click on build.bat and wait it takes a bit for first time
(build.bat closes any NextCode running from the old build folder before replacing it,
so you don't have to kill it by hand anymore)
then open the build folder and open NextCode.exe 
and after ur limit reached u just click on reset usage and it will reset your usage :D

heads up: cloudflare rate-limits new warp registrations after a few resets, and sometimes
hands back the same ip. after a few resets it can refuse for a while - when that happens the
reset console now retries a few times and then falls back to tor automatically. for the fallback
to work u need tor installed: either the Tor Browser or the tor expert bundle (tor.exe gets found
via PATH, `C:\Program Files\Tor\Tor\tor.exe` or inside a Tor Browser install).

## CLI setup (opencode, but NextCode)

`build.bat` gives u the desktop app. `setup.bat` installs the bundled engine as a real
system-wide `opencode` command, so u can run it from any terminal:

1. run `build.bat` once (needs the engine in `build\resources\opencode-cli.exe`)
2. run `setup.bat`
3. open a new terminal and type `opencode`

setup copies the engine to `%LOCALAPPDATA%\NextCode\bin\opencode.exe`, puts that folder first
on your user PATH, installs this folder's `AGENTS.md` and `SubAgents\` into
`%USERPROFILE%\.config\opencode\`, and registers `Skills\` in `opencode.json`. your existing
config is backed up and only the `skills` entry is touched. re-running setup only copies files
that changed.

after `update.bat` swaps in a newer engine, re-run `setup.bat` to refresh the global CLI.

`uninstall.bat` removes exactly the files setup wrote (tracked in
`%LOCALAPPDATA%\NextCode\installed-files.txt`), restores `opencode.json` and cleans PATH.

## Exclusive brain (unlimited / vision / files)

No Ollama, no local runtime, no API key. The brain is the NextCode-only
`opencode/*-free` roster. Run `select-nextcode-model.bat` (or `opencode models`
and `/models`) to pick one. Default is `opencode/nemotron-3.5-super-vl-free` —
vision plus code — with `opencode/hy4-flash-free` as the fast fallback.

Infinite usage is NextCode's own reset: when the free limit appears, click
**reset usage** in the desktop app. The bundled WARP local proxy rotates the
exit IP and the console retries or falls back to Tor.

New skills in `Skills\`: `nextcode-exclusive-models` (roster, vision, file
reading, memory ledger), `ncm-cognitive` (ground-truth manifest, evidence ledger,
failure breakers), `khaos-pentest-stages` (phase gates), `gods-eye-view-mcp`
(visual grounding + OSINT), `storm-breaker-lab` (lab-only phishing patterns).

New subagents in `SubAgents\`: vision, file-reader, memory, ncm, recon,
enumeration, vuln, fuzzing, authorization, authentication, exploitation, pivot,
validation, reporting, osint-globe. `setup.bat` installs all of them globally.

## Community install (one command)

Give people the zip and this line:

```
install.bat
install.bat -ApiUrl https://your-update-api.vercel.app
install.bat -Bundle NextCode-3.0.0.zip -ApiUrl https://your-update-api.vercel.app
```

`install.ps1` checks WebView2, installs Cloudflare WARP when missing (one UAC
prompt), expands a bundle if given, runs `setup.ps1`, selects the exclusive
model, persists the update API URL as `NEXTCODE_UPDATE_API` for the user, runs
`doctor.ps1 -Fix`, then smoke-tests the CLI and model. No source build needed.

`doctor.bat` (add `-Fix` to apply safe corrections) diagnoses the three failures
people reported: reset, `ECONNREFUSED` on Updates, and WARP MITM/TLS errors. The
usual `ECONNREFUSED` cause is WARP sitting in `doh` mode while the app expects
`http://127.0.0.1:40000`; `-Fix` switches it to proxy mode, sets the port and
reconnects. It also checks `NO_PROXY` for loopback addresses.

## Autoupdate via your own API

Host `api/version.ts` on Vercel or `api/server.js` on Render (see `api/README.md`).
One manifest endpoint serves every machine — no more separate exes per release.

```
autoupdate.bat -Check     report available version
autoupdate.bat            download, verify SHA-256, stage, swap, keep rollback
```

`update.ts` uses the same API and falls back to the upstream npm feed. The CLI
updater was patched to honour `NEXTCODE_UPDATE_API` as well. Logs and rollback
copies live in `backup\`.


