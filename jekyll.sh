#!/bin/bash

export JEKYLL_VERSION=3.8.6

init_git() {

    command -v git >/dev/null 2>&1 || {
        sudo apt update
        sudo apt install -y git
    }

    git config --global init.defaultBranch main

    name=$(git config user.name)
    [ -z "$name" ] && {
        read -p "User Name: " name
        git config --global user.name "$name"
    }

    email=$(git config user.email)
    [ -z "$email" ] && {
        read -p "User Email: " email
        git config --global user.email "$email"
    }
}

init_gh() {

    command -v gh >/dev/null 2>&1 || {
        sudo apt update
        sudo apt install -y gh
    }

    if grep -q "oauth_token" $HOME/.config/gh/hosts.yml; then
        :
    else
        gh auth  login -h github.com -w
    fi
}

init_jekyll() {

    mkdir -p _bundle
    mkdir -p _data
    mkdir -p _includes
    mkdir -p _layouts
    mkdir -p _site

    raw=https://raw.githubusercontent.com/xtec-dev/smx-8/main/uf5/jekyll

    echo "Dowloading default files"
    wget -q ${raw}/_data/navigation.yml -P _data
    wget -q ${raw}/_includes/footer.html -P _includes
    wget -q ${raw}/_includes/navigation.html -P _includes
    wget -q ${raw}/_layouts/default.html -P _layouts
    wget -q ${raw}/_config.yml
    rm .gitignore
    wget -q ${raw}/.gitignore
    wget -q ${raw}/Gemfile
    wget -q ${raw}/index.html
    wget -q ${raw}/about.html
    wget -q ${raw}/jekyll.sh
    chmod +x jekyll.sh

    git add *
    git commit -a -m "Init default project"
    git push
}

new() {

    init_git
    init_gh   

    repo=$(git rev-parse --git-dir 2> /dev/null)
    [ -z "$repo" ] && {
        read -p "Project Name: " project
        gh repo create $project --clone --public --gitignore Jekyll

        cd $project
        init_jekyll
    }
}

run() {

    docker run --rm \
        --env JEKYLL_UID=$UID \
        --env JEKYLL_GID=$UID \
        --volume="$PWD:/srv/jekyll" \
        --volume="$PWD/_site:/srv/jekyll/_site" \
        --volume="$PWD/_bundle:/usr/local/bundle" \
        --publish 4000:4000 \
        --publish 35729:35729 \
        jekyll/jekyll:$JEKYLL_VERSION \
        jekyll serve --livereload --incremental
}

update() {

    docker run --rm \
        --env JEKYLL_UID=$UID \
        --env JEKYLL_GID=$UID \
        --volume="$PWD:/srv/jekyll" \
        --volume="$PWD/_site:/srv/jekyll/_site" \
        --volume="$PWD/_bundle:/usr/local/bundle" \
        jekyll/jekyll:$JEKYLL_VERSION \
        bundle update
}

case $1 in
new)
    new
    ;;
run)
    run
    ;;
sync)
    gh repo sync
    ;;
update)
    update
    ;;
*)
    echo "Usage: $0 new | run | sync | update"
    ;;
esac
