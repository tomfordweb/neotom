My neovim config.


# Try it out

Build the image.

```bash
# Using nightly
docker build -t neotom .
# A specific version
docker build --build-arg TAG=v0.11.5
```

```bash
docker run -it neotom
```

# Icons

Icons can be searched [here](https://www.nerdfonts.com/cheat-sheet): copy the icon and paste it where the sign is needed in the config.

# Commands

1: `:Lazy` - Update/view dependencies.
2: `:Mason` - LSP installer.

# Uprades


Basically - nuke all cache and storage and rebuild the program.

When upgrading, It is important to clean the `$VIMRUNTIME` directory or things will act really strange!

```bash
# clean
rm -rf ~/.local/state/nvim/
rm -rf ~/.local/share/nvim/
rm -rf ~/.local/share/nvim/lazy/
rm -rf /usr/local/shre/runtime

cd <nvim-repo>
rm -rf build .deps
git checkout release-0.<version>
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install

nvim +checkhealth
# resolve any healthcheck issues

```
