# ld-vimwiki-export.vim


## PROJECT MOVED – This repository has been moved to Codeberg. The current version can be found here: https://codeberg.org/Xardas/ld-vimwiki-export.vim


A fast, lightweight, and bloat-free HTML exporter for [Vimwiki](https://github.com/vimwiki/vimwiki). 
Instead of relying on heavy Haskell dependencies (like Pandoc) or the default Vimwiki HTML engine, this plugin uses **[lowdown](https://kristaps.bsd.lv/lowdown/)** – an ultra-fast, secure Markdown translator written in C.

## Features
* **Zero Bloat:** Uses the blazing-fast `lowdown` binary instead of Pandoc.
* **Wikilinks Support:** Automatically converts standard Vimwiki `[[links]]` to proper Markdown links on the fly before HTML generation.
* **Clean URLs:** Sanitizes filenames and links (removes special characters, converts spaces to hyphens, forces lowercase) for web-safe URLs.
* **Smart CSS/JS Injection:** Automatically injects `<link>` and `<script>` tags into the generated HTML, calculating proper relative paths for nested directories.
* **Nested Folders:** Fully respects your directory structure.

## Requirements
* `lowdown` installed on your system (`sudo pacman -S lowdown` on Arch Linux).
* Vimwiki configured to use Markdown syntax.
