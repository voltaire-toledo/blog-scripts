# Installation instructions

To use the files in this directory, follow these steps:

1. **Backup your current configuration files:**
  
    ```bash
    cp ~/.bashrc ~/.bashrc.backup
    cp ~/.bash_aliases ~/.bash_aliases.backup
    ```

1. **Amend your `.bashrc` and `.bash_aliases`:**

    - Replace or append the contents of the provided `bashrc` and `bash_aliases` files to your home directory:
      ```bash
      cat ./bashrc >> ~/.bashrc
      cat ./bash_aliases >> ~/.bash_aliases
      ```

    - Alternatively, you can copy them directly (overwriting existing files):
      ```bash
      cp ./bashrc ~/.bashrc
      cp ./bash_aliases ~/.bash_aliases
      ```

2. **Reload your shell configuration:**
3. 
  ```bash
  source ~/.bashrc
  ```

**Note:** Review the contents of these files before applying to ensure they meet your requirements.

## One-line automatic installation

To run the installation script directly from GitHub without cloning the repository, use:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gh-voltaire-toledo/blog-scripts/main/BourneAgainShell/bashrc/install-rc.sh)
```

**Note:** Always review scripts from the internet before running them.