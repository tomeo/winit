# Show installed vscode packages:
# code --list-extensions --show-versions
scoop install vscode
code --install-extension DavidAnson.vscode-markdownlint
code --install-extension humao.rest-client
code --install-extension phplasma.csv-to-table
code --install-extension EditorConfig.EditorConfig
code --install-extension SimonSiefke.svg-preview
code --install-extension adamhartford.vscode-base64
code --install-extension neilding.language-liquid
code --install-extension svelte.svelte-vscode
code --install-extension James-Yu.latex-workshop
code --install-extension JakeBecker.elixir-ls
code --install-extension phoenixframework.phoenix

scoop install nodejs-lts
node ./configure-vscode-settings.js
