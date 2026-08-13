# Show installed vscode packages:
# code --list-extensions --show-versions
scoop install vscode

# General
code --install-extension adamhartford.vscode-base64
code --install-extension adpyke.vscode-sql-formatter
code --install-extension alefragnani.project-manager
code --install-extension anthropic.claude-code
code --install-extension bierner.markdown-mermaid
code --install-extension deerawan.vscode-dash
code --install-extension editorconfig.editorconfig
code --install-extension humao.rest-client
code --install-extension mintlify.document
code --install-extension oderwat.indent-rainbow
code --install-extension phplasma.csv-to-table
code --install-extension satoshiyamamoto.vscode-end-of-line
code --install-extension simonsiefke.svg-preview
code --install-extension xirider.livecode

# Git
code --install-extension codezombiech.gitignore
code --install-extension donjayamanne.git-extension-pack
code --install-extension donjayamanne.githistory
code --install-extension eamodio.gitlens
code --install-extension ziyasal.vscode-open-in-github

# Python
code --install-extension almenon.arepl
code --install-extension batisteo.vscode-django
code --install-extension cstrap.python-snippets
code --install-extension demystifying-javascript.python-extensions-pack
code --install-extension kaih2o.python-resource-monitor
code --install-extension kevinrose.vsc-python-indent
code --install-extension littlefoxteam.vscode-python-test-adapter
code --install-extension ms-python.debugpy
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.vscode-python-envs
code --install-extension njpwerner.autodocstring
code --install-extension njqdev.vscode-python-typehint
code --install-extension sourcery.sourcery
code --install-extension thebarkman.vscode-djaneiro
code --install-extension trabpukcip.wolf

# Testing
code --install-extension hbenl.vscode-test-explorer
code --install-extension ms-vscode.test-adapter-converter

# Azure and containers
code --install-extension ms-azuretools.vscode-azurefunctions
code --install-extension ms-azuretools.vscode-azureresourcegroups
code --install-extension ms-azuretools.vscode-containers
code --install-extension ms-azuretools.vscode-docker

# Languages
code --install-extension jakebecker.elixir-ls
code --install-extension james-yu.latex-workshop
code --install-extension neilding.language-liquid
code --install-extension phoenixframework.phoenix
code --install-extension redhat.vscode-xml
code --install-extension svelte.svelte-vscode

scoop install nodejs-lts
node ./configure-vscode-settings.js
