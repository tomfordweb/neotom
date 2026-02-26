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
