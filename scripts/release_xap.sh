#!/bin/bash
source setenv.sh
#export WORKSPACE=/home/barakbo/tmp/workspace
#export BRANCH=xap-renaming-m3
#export VERSION=12.0.0-m6
#export BUILD_NUMBER=1
#export M2=/home/barakbo/tmp/m2
#export SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function get_folder {
    echo -n "${WORKSPACE}/$(echo -e $1 | sed 's/.*\/\(.*\)\.git/\1/')"
}

function clean_branch {
    local folder="$1"
    local branch="$2"
    echo "clean branch ${branch} in workspace ${folder}"
    (
      cd "${folder}"
      git reset --hard HEAD
      git checkout -- .
      git clean -d -f -q -x .
      git gc --auto
      git checkout "${branch}"
      return "$?"
    ) 
}

function clone {
    local url="$1"
    local branch="$2"
    local folder="$(get_folder $1)"
  
    if [ -d "${folder}" ]
    then
        clean_branch "${folder}" "${branch}"
        if [ $? -eq 0 ]
        then
    	    return 0;
        fi
    fi
    rm -rf "${folder}"
    git clone "${url}" "${folder}" 
    clean_branch "${folder}" "${branch}"
}

function release_xap{

}

clone "git@github.com:Gigaspaces/xap-open.git" "${BRANCH}" 
clone "git@github.com:Gigaspaces/xap.git" "${BRANCH}" 



