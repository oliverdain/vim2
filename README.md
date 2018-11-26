This is my current vim setup.

To setup on a new machine:

1. Clone this repo
2. Open vim and run `PluginInstall` to install all the plugins
3. For neovim you may also need to run [`UpdateRemotePlugins`](https://neovim.io/doc/user/remote_plugin.html)

That's it for *basic* functionality.

Language specific:

For C++ completion you will also want to clone and build
[cquery](https://github.com/cquery-project/cquery/wiki/Building-cquery), the [Language Server
Protocol](https://github.com/Microsoft/language-server-protocol) server for C++ completions, fixes, etc. After that you
will also have to change into the `~/.vim/bundle/LanguageClient-neovim` directory and run `bash install.sh`.
