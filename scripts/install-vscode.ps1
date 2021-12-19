scoop install vscode
code --install-extension DavidAnson.vscode-markdownlint
code --install-extension humao.rest-client
code --install-extension phplasma.csv-to-table
code --install-extension EditorConfig.EditorConfig
code --install-extension SimonSiefke.svg-preview
code --install-extension adamhartford.vscode-base64
code --install-extension neilding.language-liquid
code --install-extension svelte.svelte-vscode

scoop install nodejs-lts
node ./configure-vscode-settings.js
