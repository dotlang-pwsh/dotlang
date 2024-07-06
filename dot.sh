#!/bin/bash

#    __  __             _                    _  _    _        ____          _     _____  _       _____ 
#   |  \/  |           | |                  (_)| |  | |      |  _ \        | |   / ____|| |     |_   _|
#   | \  / |  __ _   __| |  ___   __      __ _ | |_ | |__    | |_) |  __ _ | |_ | |     | |       | |  
#   | |\/| | / _` | / _` | / _ \  \ \ /\ / /| || __|| '_ \   |  _ <  / _` || __|| |     | |       | |  
#   | |  | || (_| || (_| ||  __/   \ V  V / | || |_ | | | |  | |_) || (_| || |_ | |____ | |____  _| |_ 
#   |_|  |_| \__,_| \__,_| \___|    \_/\_/  |_| \__||_| |_|  |____/  \__,_| \__| \_____||______||_____|
#                                                                                                      
#                                                                                                      

# dotlang, (C) 2024 NEOAPPS
# This code is licensed under MIT license (see LICENSE.txt for details)

version=1
script_dir="$(dirname "$(realpath "$0")")"

function print_help {
    echo "dotCLI - The CLI for dotlang."
    echo "Current dot Version Installed: dot v$version."
    echo
    echo "Usage:"
    echo -e "\\033[4mdot\\033[0m --help, -h, /?          Show help Page"
    echo -e "\\033[4mdot\\033[0m build                Build Project in the current directory"
    echo -e "\\033[4mdot\\033[0m new                  Make a project in the current directory"
    echo -e "\\033[4mdot\\033[0m add PACKAGE          Adds PACKAGE to the current project"
}

function create_new_project {
    if [ -f "$PWD/dot.json" ]; then
        echo -e "\\033[1;31mWARNING: PROJECT IN THIS DIRECTORY ALREADY EXISTS. IF YOU WANT TO OVERRIDE IT, MAKE A FILE WITH NAME \"override.txt\".\\033[0m"
        if [ -f "override.txt" ]; then
            echo "{\"dotv\":\"$version\", \"name\":\"mydot\", \"v\": \"0.1\", \"packages\": []}" >dot.json
            rm -f override.txt
            echo "Project with name 'mydot' has been made in $PWD."
        fi
    else
        echo "{\"dotv\":\"$version\", \"name\":\"mydot\", \"v\": \"0.1\", \"packages\": []}" >dot.json
		echo "Import-Module .\dot.ps1 # Enable dotlang">main.dot
        echo "Project with name 'mydot' has been made in $PWD."
    fi
}

function build_project {
    echo "[dot.build] Reinitialized build.log file." >build.log
    echo "[dot] Building project from $PWD..."
    echo "[dot] Building project from $PWD..." >>build.log
    sleep 1
    dotv=$(jq -r .dotv dot.json)
    if [ "$version" -lt "$dotv" ]; then
        echo "[dot] You're using an outdated version of dot. please install dot $dotv or more"
        exit 1
    fi
    echo "[dot] Getting the latest packages from $PWD/dot.json..."
    echo "[dot] Getting the latest packages from $PWD/dot.json..." >>build.log
    packages=$(jq -r ".packages[]" dot.json)
    for child in $packages; do
        echo "[dot] Running: ship install $child"
        echo "[dot] Running: ship install $child" >>build.log
        echo "[dot] Begin 'ship install $child' log.." >>build.log
        ship install "$child" >>build.log
        echo "[dot] End 'ship install $child' log.." >>build.log
        sleep 2
    done
    echo "[dot] Building project..."
    echo "[dot] Building project..." >>build.log
    rm -rf dist
    mkdir dist >>build.log
    cp *.dot dist/ >>build.log
    cp *.exe dist/ >>build.log
    cp *.dll dist/ >>build.log
    cp $script_dir/dot.ps1 dist/ >>build.log
    cd dist || exit
    for f in *.dot; do mv -- "$f" "${f%.dot}.ps1"; done
    cd ..
    echo "[dot.build] End build.log." >>build.log
    echo "[dot] Build finished, check $PWD/build.log for the full log. (ERRORCODE: $?)"
    exit $?
}

function add_package {
    packages=$(jq -r -c ".packages" "dot.json")
    packages="${packages#[}"
    packages="${packages%]}"
    echo "{\"dotv\":\"$version\", \"name\":\"mydot\", \"v\": \"0.1\", \"packages\": [$packages, \"$2\"]}" >dot2.json
    jq -r -s -c add "dot2.json" "dot.json" >dot.json
    rm -f dot2.json
    echo "[dot] Package has been added to 'dot.json' with error code ($?)"
    exit $?
}

case "$1" in
    --help|-h|"/?")
        print_help
        ;;
    build)
        build_project
        ;;
    new)
        create_new_project
        ;;
    add)
        add_package "$@"
        ;;
    idk)
        echo "it's alright. idk too hehe"
        ;;
    *)
        echo "Invalid Syntax! use 'dot --help' for help."
        ;;
esac
