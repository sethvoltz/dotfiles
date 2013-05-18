# Thanks to Hacker Codex for the great tutorial.
# http://hackercodex.com/guide/python-virtualenv-on-mac-osx-mountain-lion-10.8/

# Also, http://www.insomnihack.com/?p=442

# Virtualenv should use Distribute instead of legacy setuptools
export VIRTUALENV_DISTRIBUTE=true

# Centralized location for new virtual environments
export PIP_VIRTUALENV_BASE=$HOME/.virtualenvs
export WORKON_HOME=$PIP_VIRTUALENV_BASE

# Pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=true

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

syspip() {
   PIP_REQUIRE_VIRTUALENV="" pip "$@"
}

syspip3() {
   PIP_REQUIRE_VIRTUALENV="" pip3 "$@"
}
