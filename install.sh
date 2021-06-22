#!/usr/bin/env bash

set -e
set -o pipefail

readonly APP_NAME="dvim"
readonly APP_SETUP_NAME=".vim"
readonly APP_PATH="$HOME/$APP_SETUP_NAME"
readonly REPO_PATH="$HOME/$APP_SETUP_NAME"
readonly CONFIG_PATH="$HOME/$APP_SETUP_NAME/config"
readonly NVIM_PATH="$HOME/.config/nvim"
readonly REPO_URI="https://github.com/mdvis/$APP_NAME.git"

is_debug="0"

debug() {
    if [ "$is_debug" -eq "1" ] && [ "$ret" -gt "1" ]; then
        msg "${FUNCNAME[1]}/${BASH_LINENO[1]}"
    fi
}

msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq "0" ]; then
        msg "\033[32m[✔]\033[0m ${1}${2}"
    fi
}

error() {
    msg "\033[31m[✘]\033[0m ${1}${2}"
    exit 1
}

initWorkDir() {
    dirList="$*"

    for fileName in $dirList; do
        [ -d "$fileName" ] || mkdir "$fileName"

        ret="$?"
        success "$fileName was created!"
        debug
    done
}

lnif() {
    fileName=$1
    sourceDir=$2
    targetDir=$3
    sourcePrefix=$4
    targetPrefix=$5

    sourcePath="$sourceDir/$sourcePrefix$fileName"
    targetPath="$targetDir/$targetPrefix$fileName"

    if [ -e "$sourcePath" ]; then
        ln -sf "$sourcePath" "$targetPath"
    fi

    ret="$?"
    success "$sourcePath was linked!"
    debug
}

syncRepo() {
    local repo_path="$1"
    local repo_uri="$2"

    if [ ! -e "$repo_path" ]; then
        mkdir -p "$repo_path"
        git clone "$repo_uri" "$repo_path"
    else
        cd "$repo_path" && git pull origin master
    fi

    ret="$?"
    success "Dvim clone done!"
    debug
}

installPlugins() {
    type nvim >/dev/null 2>&1 || local hasNvim="vim"
    local systemShell="$SHELL"

    export SHELL='/bin/sh'

    if [ "$hasNvim" = "vim" ]; then
        vim "+PlugInstall!" "+PlugClean" "+qall"
    else
        nvim "+PlugInstall!" "+PlugClean" "+qall"
    fi

    export SHELL="$systemShell"

    ret="$?"
    success "Plugins setup done!"
    debug
}

getFile() {
    local dir_name=$1
    dir_list=$(/usr/bin/find "${dir_name}" -depth 1)
}

handler() {
    local dir
    local file
    local path_name="$1"
    local target_dir="$2"
    getFile "${path_name}"
    for i in ${dir_list}; do
        dir=$(dirname "$i")
        file=$(basename "$i")
        echo "${dir}/${file} ---> ${target_dir}${file}"
        lnif "${dir}/${file}" "${target_dir}${file%.sh}"
    done
}

initWorkDir "$HOME/.swp" \
    "$HOME/.backup" \
    "$HOME/.undo" \
    "$NVIM_PATH" \

syncRepo "$REPO_PATH" \
    "$REPO_URI"

handler "${CONFIG_PATH}" "$HOME/."

installPlugins
