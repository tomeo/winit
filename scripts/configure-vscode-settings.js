const fs = require('fs')

const path = `${process.env.USERPROFILE}/scoop/apps/vscode/current/data/user-data/User/settings.json`;

fs.readFile(path, 'utf8' , (err, data) => {
  let settings = JSON.parse(data || '{}');

  settings['editor.formatOnSave'] = false;
  settings['editor.minimap.enabled'] = false;
  settings['editor.largeFileOptimizations'] = false;
  settings['editor.fontFamily'] = 'FiraCode NF';
  settings['editor.fontLigatures'] = true;
  settings['editor.fontSize'] = 11;
  settings['editor.renderWhitespace'] = 'all';

  settings['files.eol'] = '\n';

  settings['javascript.updateImportsOnFileMove.enabled'] = 'always';

  settings['workbench.colorTheme'] = 'Solarized Dark';
  settings['workbench.editor.showIcons'] = false;
  settings['workbench.activityBar.visible'] = false;
  
  settings['window.menuBarVisibility'] = 'default';
  settings['window.zoomLevel'] = 1;

  fs.writeFileSync(path, JSON.stringify(settings, null, 2));
})