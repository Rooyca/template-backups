# template-backups

## Checklist

- [ ] SET THE REMOTE REPO TO PRIVATE!!!
- [ ] Dotfiles in `~/.config`
- [ ] Folders in `~/.local/share/`
- [ ] Bookmarks
- [ ] Fonts
- [ ] Themes
- [ ] `~/.ssh` folder¹
- [ ] PGP Keys²
- [ ] Program & packages names
  - [ ] system
  - [ ] npm
  - [ ] ruby
  - [ ] pip
  - [ ] Others
- [ ] ...

---
1. Even if you set this repository to private, you should not store the `~/.ssh` folder on GitHub.
2. Just like with the `~/.ssh` folder, you should not store PGP keys on GitHub.

## Running the script

```bash
chmod +x rookup.sh
./rookup.sh
```

|Variable|Description|Default|
|---|---|---|
|`DONT_BACKUP`|Directories to ignore (separated by ',')|""|
|`BACKUP_DIR`|Directory to store the backup|`~/rokup`|

If you want to add more directories to ignore, you can do it like this:

```bash
export DONT_BACKUP="pnpm,gem,Trash"
```

## PGP Keys

### Exporting

```bash
gpg --export-secret-keys <key-id> > private.key
gpg --export <key-id> > public.key
```

### Importing

```bash
gpg --import private.key
gpg --import public.key
```