# 🦊 Firefox Clean Menu Icons

> Restore clean, beautiful icons to Firefox context menus and the hamburger menu without 30,000 lines of breaking CSS.

[![Firefox](https://img.shields.io/badge/Firefox-130%2B-orange.svg)](https://www.mozilla.org/firefox/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-0-green.svg)]()
[![Pure CSS](https://img.shields.io/badge/Code-Vanilla%20CSS-blueviolet.svg)]()

---

## 💡 The Problem

Ever since the **Proton UI** update in Firefox 89, Mozilla stripped all icons from context menus and the main hamburger menu, leaving behind a sterile wall of text.

Existing community solutions like **Lepton (Firefox-UI-Fix)** attempt to fix this, but come at a steep cost:
- ❌ **30,000+ lines of compiled SCSS** that try to redesign the entire browser.
- ❌ **Breaks frequently** upon new Firefox releases (causing white-on-white text, black square borders around rounded popups, broken New Tab shortcut tiles, etc.).
- ❌ Complex build pipelines requiring Node.js, Yarn, and Sass.

Other older snippets on GitHub and Gist are mostly abandoned and lack support for modern Firefox additions (such as the AI Chatbot, built-in Translations, etc.).

---

## ✨ The Solution: Clean Menu Icons

**Firefox Clean Menu Icons** follows the UNIX philosophy: **do one thing, and do it well**.

* 🚀 **Ultra-lightweight:** ~170 lines of pure, standard CSS. No compilers, no dependencies.
* 🎨 **Native rendering:** Does **not** touch your theme's background colors, window geometry, shadows, or border-radius. Native dark and light modes work out of the box.
* 📦 **Complete coverage:**
  * **Page Context Menu** (Save Page As, Select All, Take Screenshot, View Source, Inspect, etc.)
  * **Links & Media** (Open in New Tab, Bookmark Link, Save Image/Video, Copy Link, etc.)
  * **Editing & Selection** (Undo, Redo, Cut, Copy, Paste, Delete, Search Google)
  * **Tab Context Menu** (Reload, Pin, Duplicate, Mute, Close Tab)
  * **Bookmarks Context Menu** (Open in New Tab, New Folder, Edit, Delete)
  * **Hamburger App Menu** (`#appMenu-multiView` — New Tab, Window, History, Bookmarks, Downloads, Passwords, Settings, More Tools, Help, Exit)
  * **Modern Firefox Features** (AI Chatbot, Translations, Container Tabs)
* 🛡️ **Update-proof:** Because it only targets icon presentation and labels, future Firefox updates won't break your browser's layout.

---

## 📥 Installation (in 3 easy steps)

### Step 1: Enable `userChrome.css` in Firefox
1. Open Firefox and type `about:config` into the address bar. Press <kbd>Enter</kbd>.
2. Click **"Accept the Risk and Continue"**.
3. Search for `toolkit.legacyUserProfileCustomizations.stylesheets`.
4. Double-click it (or click the toggle button) to set it to **`true`**.

### Step 2: Open your Profile Folder
1. In Firefox, open `about:support`.
2. Find the row named **Profile Folder** (or **Profile Directory**) and click **Open Folder**.
3. In that folder, check if a folder named `chrome` exists. If not, create it.

### Step 3: Copy the Files
1. Copy the `icons/` folder and the `css/` folder from this repository into your `chrome/` folder:
   ```
   [Your Profile Folder]/
   └── chrome/
       ├── css/
       │   └── clean-menu-icons.css
       ├── icons/
       │   ├── new-tab.svg
       │   ├── toolbarButton-download.svg
       │   └── ...
       └── userChrome.css
   ```
2. In your `chrome/userChrome.css` (create it if you don't have one), add this single line at the top:
   ```css
   @import url("css/clean-menu-icons.css");
   ```
3. Restart Firefox. Enjoy! 🎉

---

## 🎨 Compatibility

- **OS:** Windows 10/11, macOS, Linux.
- **Firefox:** Tested and verified on **Firefox 130+ through Firefox 154+**.
- **Themes:** Fully compatible with Default Dark, Default Light, Alpenglow, and custom WebExtension themes.

---

## 🤝 Contributing

Found a menu item that's missing an icon or need an icon for a new Firefox feature? Pull requests and issues are very welcome!

---

## 📄 License

[MIT License](LICENSE) © 2026 Alina Lisova
