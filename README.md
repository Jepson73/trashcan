# A safer alternative to the `rm` command that moves files to a trash directory instead of permanently deleting them.

## Features

- Safely move files to trash instead of immediate deletion
- Restore accidentally trashed files
- Empty trash when you're sure you want to delete
- Similar syntax to the familiar `rm` command
- Works across all directories

## Installation

### Option 1: Direct installation (recommended)

```bash
curl -s https://raw.githubusercontent.com/Jepson73/trashcan/main/trash.sh | sudo tee /usr/local/bin/trash > /dev/null && sudo chmod 755 /usr/local/bin/trash
```

### Option 2: Manual installation

```bash
# Clone the repository
git clone https://github.com/Jepson73/trash.git

# Move to the repository directory
cd trash

# Install the script
sudo cp trash.sh /usr/local/bin/trash
sudo chmod 755 /usr/local/bin/trash
```

## Uninstallation

If you no longer need trash.sh, you can uninstall it by following these steps:
Remove the script

sudo rm -f /usr/local/bin/trash

Remove the trash directory (optional)

By default, trashed files are stored in ~/.trash. If you want to remove all trashed files and the directory, run:

rm -rf ~/.trash

    ⚠️ Warning: This action is irreversible and will permanently delete all trashed files.

If you have configured a custom trash directory, you may also want to remove it manually.

## Usage

```bash
# Move files to trash
trash file1.txt file2.txt

# Move directories to trash
trash -r directory1/

# List trashed files
trash --list

# Restore a file from trash
trash --restore filename.txt

# Empty the trash
trash --empty
```

## Configuration

By default, trash.sh uses `~/.trash` as the trash directory. You can customize this by setting the `TRASH_DIR` environment variable in your `.bashrc` or `.zshrc` file:

```bash
export TRASH_DIR="/path/to/custom/trash"
```

## License

This project is licensed under the GNU General Public License v3 (GPL-3.0) - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
