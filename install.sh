#!/usr/bin/env bash
set -e

echo "==================================================="
echo "  Firefox Clean Menu Icons - Easy Installer"
echo "==================================================="
echo ""

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PROFILE=""

if [[ "$OSTYPE" == "darwin"* ]]; then
    FF_DIR="$HOME/Library/Application Support/Firefox"
elif [ -d "$HOME/.mozilla/firefox" ]; then
    FF_DIR="$HOME/.mozilla/firefox"
elif [ -d "$HOME/snap/firefox/common/.mozilla/firefox" ]; then
    FF_DIR="$HOME/snap/firefox/common/.mozilla/firefox"
elif [ -d "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" ]; then
    FF_DIR="$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
fi

if [ -z "$FF_DIR" ] || [ ! -d "$FF_DIR" ]; then
    echo "[-] Error: Firefox directory not found."
    echo "    Checked:"
    echo "    - \$HOME/.mozilla/firefox"
    echo "    - \$HOME/Library/Application Support/Firefox"
    echo "    - \$HOME/snap/firefox/common/.mozilla/firefox"
    echo "    - \$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
    exit 1
fi

PROFILES_INI="$FF_DIR/profiles.ini"

read_profiles_ini() {
    local ini="$1"
    local clean_data rel=""
    clean_data="$(tr -d '\r' < "$ini")"

    rel=$(awk '
        /^\[/{inst = ($0 ~ /^\[Install/) ? 1 : 0; next}
        inst && /^Default=/ {sub(/^[^=]*=/, ""); gsub(/^[\t ]+|[\t ]+$/, ""); print; exit}
    ' <<<"$clean_data")

    if [ -z "$rel" ]; then
        rel=$(awk '
            {ln = $0}
            /^\[/{prof = (ln ~ /^\[Profile/) ? 1 : 0; p = ""; d = 0; next}
            !prof {next}
            {v = ln; sub(/^[^=]*=/, "", v); gsub(/^[\t ]+|[\t ]+$/, "", v)}
            /^Path=/                {p = v; if (p != "" && d) {print p; exit}}
            /^Default=1([\t ]*)?$/  {d = 1; if (p != "") {print p; exit}}
        ' <<<"$clean_data")
    fi

    if [ -z "$rel" ]; then
        rel=$(awk -F= '
            /^Path=.*\.default(-release)?([\t ])*$/ {sub(/[\t ]*$/, "", $2); print $2; exit}
        ' <<<"$clean_data")
    fi

    echo "$rel"
}

if [ -f "$PROFILES_INI" ]; then
    REL_PATH=$(read_profiles_ini "$PROFILES_INI")
    if [ -n "$REL_PATH" ]; then
        case "$REL_PATH" in
            /*) TARGET_PROFILE="$REL_PATH" ;;
            *)  TARGET_PROFILE="$FF_DIR/$REL_PATH" ;;
        esac
    fi
fi

if [ -z "$TARGET_PROFILE" ] || [ ! -d "$TARGET_PROFILE" ]; then
    TARGET_PROFILE=$(find "$FF_DIR" -maxdepth 2 -type d \( -name "*.default-release" -o -name "*.default" \) 2>/dev/null | head -n 1)
fi

if [ -z "$TARGET_PROFILE" ] || [ ! -d "$TARGET_PROFILE" ]; then
    echo "[-] Error: Could not automatically detect a Firefox profile."
    exit 1
fi

echo "[+] Found Firefox profile: $(basename "$TARGET_PROFILE")"

if [ ! -d "$REPO_DIR/css" ] || [ ! -d "$REPO_DIR/icons" ]; then
    echo "[-] Error: css or icons directory is missing next to install.sh."
    exit 1
fi

CHROME_DIR="$TARGET_PROFILE/chrome"
USER_JS="$TARGET_PROFILE/user.js"
USER_CHROME="$CHROME_DIR/userChrome.css"

BACKUP_STAMP="$(date -u +%Y%m%d-%H%M%S)"
BACKUP_SUFFIX=".firefox-clean-menu-icons-backup-$BACKUP_STAMP"
BACKUP_COUNT=0

backup_file() {
    local source="$1"
    local backup="${source}${BACKUP_SUFFIX}"
    local temp
    local suffix=1

    if [ -L "$source" ] || [ ! -f "$source" ]; then
        echo "[-] Error: cannot create a file backup for $source"
        return 1
    fi

    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="${source}${BACKUP_SUFFIX}-${suffix}"
        suffix=$((suffix + 1))
    done

    temp="$(mktemp "${backup}.tmp.XXXXXX")" || return 1
    if ! cp -p "$source" "$temp" || ! cmp -s "$source" "$temp" || ! mv "$temp" "$backup"; then
        rm -f "$temp"
        echo "[-] Error: backup verification failed for $source"
        return 1
    fi

    BACKUP_COUNT=$((BACKUP_COUNT + 1))
}

backup_directory_files() {
    local source_dir="$1"
    local target_dir="$2"
    local source_file relative_path target_file

    while IFS= read -r -d '' source_file; do
        relative_path="${source_file#"$source_dir/"}"
        target_file="$target_dir/$relative_path"
        if [ -e "$target_file" ] || [ -L "$target_file" ]; then
            if ! backup_file "$target_file"; then
                return 1
            fi
        fi
    done < <(find "$source_dir" -type f -print0)
}

if [ -f "$USER_JS" ] && ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$USER_JS"; then
    if ! backup_file "$USER_JS"; then
        exit 1
    fi
fi

if [ -f "$USER_CHROME" ] && ! grep -q "clean-menu-icons.css" "$USER_CHROME"; then
    if ! backup_file "$USER_CHROME"; then
        exit 1
    fi
fi

if ! backup_directory_files "$REPO_DIR/css" "$CHROME_DIR/css" || \
   ! backup_directory_files "$REPO_DIR/icons" "$CHROME_DIR/icons"; then
    exit 1
fi

mkdir -p "$CHROME_DIR"

if ! cp -r "$REPO_DIR/css" "$CHROME_DIR/" ; then
    echo "[-] Error: failed to copy css into $CHROME_DIR"
    echo "    If it partially copied, remove chrome/css inside this profile and run again."
    exit 1
fi
if ! cp -r "$REPO_DIR/icons" "$CHROME_DIR/" ; then
    echo "[-] Error: failed to copy icons into $CHROME_DIR"
    echo "    To reset, remove chrome/css and chrome/icons inside this profile and run again."
    exit 1
fi
echo "[+] Copied css and icons to $CHROME_DIR"

PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
if [ -f "$USER_JS" ]; then
    if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$USER_JS"; then
        echo "" >> "$USER_JS"
        echo "$PREF" >> "$USER_JS"
    fi
else
    echo "$PREF" > "$USER_JS"
fi
echo "[+] Enabled userChrome stylesheets in user.js"

IMPORT_LINE='@import url("css/clean-menu-icons.css");'
if [ -f "$USER_CHROME" ]; then
    if ! grep -q "clean-menu-icons.css" "$USER_CHROME"; then
        TMP_FILE=$(mktemp)
        echo "$IMPORT_LINE" > "$TMP_FILE"
        echo "" >> "$TMP_FILE"
        cat "$USER_CHROME" >> "$TMP_FILE"
        mv "$TMP_FILE" "$USER_CHROME"
        echo "[+] Added clean-menu-icons import to userChrome.css"
    else
        echo "[+] clean-menu-icons is already imported in userChrome.css"
    fi
else
    echo "$IMPORT_LINE" > "$USER_CHROME"
    echo "[+] Created userChrome.css with clean-menu-icons import"
fi

echo ""
echo "==================================================="
echo "  [OK] Installation completed successfully!"
echo "  Please restart Firefox to apply the changes."
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo "  Verified backups created: $BACKUP_COUNT"
    echo "  Backup suffix: $BACKUP_SUFFIX"
    echo "  Backups are located next to the original files."
else
    echo "  No existing files required a backup."
fi
echo "==================================================="
