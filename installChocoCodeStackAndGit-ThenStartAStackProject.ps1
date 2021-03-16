# Windows 10 VSCode & Stack installation and Stack project generation
#
# You need to launch PowerShell as admin to install stuff with Chocolatey and Chocolatey itself

param([Parameter(Mandatory=$true)] $Name, $Path = '.')

if (!$Name) {
  throw 'Please pass a project name with the option "-Name $MyNewStackProjectName".'
}

function Is-Installed {    
  param ($commandName)  
  Get-Command $commandName -ErrorAction SilentlyContinue
}

if (!(Is-Installed "code") -or !(Is-Installed "stack") -or !(Is-Installed "git") ) {
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (!$isAdmin) {
    throw 'I want to install thing with Chocolatey. Please restart PowerShell as administrator.'
  }

  # Install Chocolatey (Windows package manager)
  if (!(Is-Installed "choco" )) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  }
  # Install VSCode & Stack using Chocolatey
  if (!(Is-Installed "code" )) {
    choco install vscode -y
  }
  if (!(Is-Installed "stack" )) {
    choco install haskell-stack -y
  }
  if (!(Is-Installed "git" )) {
    choco install git -y
    refreshenv
    git config --global core.autocrlf input
    code --install-extension eamodio.gitlens
  }
  refreshenv
}

# Admin permissions no longer necessary after this point

# Install VSCode haskell plugin
code --install-extension haskell.haskell

# =======================
# Stack project creation.
# =======================
# You can also put these things into a custom Stack project template.

# Create new Stack project
cd $Path
if (Test-Path -Path $Name -PathType Container) {
  throw "The folder $Name already exists. Get rid of it or use a different `"-Name`" to create a new project."
}
stack new $Name
cd $Name

# Needed for the VSCode haskell plugin to use Stack
# Add to stack.yaml:
# ghc-options:
#  "$everything": -haddock
Add-Content 'stack.yaml' @'

ghc-options:
 "$everything": -haddock
'@

# Needed on Windows for Stack
# Create hie.yaml with:
# cradle:
#   stack:
New-Item 'hie.yaml'
Set-Content  'hie.yaml' @'
cradle:
  stack:
'@

git init
git add -A

# Open the project folder in VSCode
code .

# Notes:
#
# Files you want to edit to manage the project (that affect compilation):
# - package.yaml
#   - Add "dependencies" for stuff that is on Stackage or just hidden
# - stack.yaml
#   - Add "extra-deps" for stuff that is not on Stackage
#   - Add "default-extensions" instead of using a LANGUAGE pragma:
#     - "{-# LANGUAGE GADTs #-}"
#        ->
#       """
#       default-extensions:
#       - GADTs
#       """
#
# Files not to edit (they will be overwritten during the build process):
# - *.cabal
#
# If the language server is complaining, where you think it shouldn't:
# - Ctrl + Shft + P -> >Haskell: Restart Haskell LSP server
#   - Do this after adding new packages as dependencies in package.yaml
#
# GHCI:
# - Ctrl + ~ -> >stack ghci
#
# There is an error reported in Setup.hs:
# - "Could not load module ‘Distribution.Simple’"
# - You can safely ignore this.
# - See: https://github.com/haskell/haskell-language-server/issues/335
