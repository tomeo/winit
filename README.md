# Initialise Windows

Scripts to init Windows.

## Prereqs

```Powershell
Set-ExecutionPolicy AllSigned
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
```

## Run initialise

Open PowerShell as administrator and run scripts from ./scripts:
```Powershell
./scripts/remap-caps-lock-to-ctrl.ps1
./scripts/set-keyboard-layouts.ps1
...
```

## Documentation
* [Custom prompt setup](https://docs.microsoft.com/en-us/windows/terminal/tutorials/custom-prompt-setup)