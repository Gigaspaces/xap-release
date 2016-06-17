#!/bin/bash
source setenv.sh


# Get the folder by git url
# $1 is a git url of the form git@github.com:Gigaspaces/xap-open.git
# The function will return a folder in the $WORKSPACE that match this git url (for example $WORKSPACE/xap-open)
function get_folder {
    echo -n "$WORKSPACE/$(echo -e $1 | sed 's/.*\/\(.*\)\.git/\1/')"
}

# Try to checkout the branch $BRANCH in the git folder $1
# Discard all local commits and local modifications, calling this function will loose all local commits and local changes.
# It will remove any untracked file as well.
# It return nonezero status in case of error, to signal that new clone is needed.
function checkout_branch {
    local folder="$1"
    (
      cd "$folder"
      git reset --hard HEAD
      git checkout -- .
      git clean -d -f -q -x .
      git gc --auto
      git checkout "$BRANCH"
      return "$?"
    ) 
}

# Try to checkout branch $BRANCH in git folder $1.
# In case of failuer delete folder $1 and use fresh clone to create this folder.
function clone {
    local url="$1"
    local folder="$(get_folder $1)"
  
    if [ -d "$folder" ]
    then
        checkout_branch "$folder" "$branch"
        if [ $? -eq 0 ]
        then
    	    return 0;
        fi
    fi
    rm -rf "$folder"
    git clone "$url" "$folder" 
    checkout_branch "$folder"
}

# Rename all version of each pom in $1 folder with $VERSION
function rename_poms {
    local version="$(grep -m1 '<version>' $1/pom.xml | sed 's/<version>\(.*\)<\/version>/\1/')"
    local trimmed_version="$(echo -e "${version}" | tr -d '[[:space:]]')"
    find "$1" -name "pom.xml" -exec sed -i.bak "s/$trimmed_version/$VERSION/" \{\} \;
}


function create_temp_branch {
    local temp_branch_name="$1"
    local git_folder="$2"
    (
     cd "$git_folder"
     git checkout "$BRANCH"
     git show-ref --verify --quiet "refs/heads/$temp_branch_name"
     if [ "$?" -eq 0 ]
     then
	 git branch -D  "$temp_branch_name"
     fi
     git checkout -b "$temp_branch_name"
    )
}

function clean_m2 {
    rm -rf $M2/repository/org/xap      
    rm -rf $M2/repository/org/gigaspaces 
    rm -rf $M2/repository/com/gigaspaces 
    rm -rf $M2/repository/org/openspaces 
    rm -rf $M2/repository/com/gs         
}


function mvn_install {
    (
       pushd "$1"
       cmd="mvn -Dmaven.repo.local=$M2/repository -DskipTests install"
       eval "$cmd"
       local r="$?"
       popd
       if [ "$r" -ne 0 ]
       then
          echo "[ERROR] Failed While installing using maven in folder: $1, command is: $cmd, exit code is: $r"
          times
          exit "$r"
       fi
    )
}

function mvn_deploy {
    (
       pushd "$1"
       cmd="mvn -Dmaven.repo.local=$M2/repository -DskipTests deploy:deploy"
       eval "$cmd"
       local r="$?"
       popd
       if [ "$r" -ne 0 ]
       then
          echo "[ERROR] Failed While installing using maven in folder: $1, command is: $cmd, exit code is: $r"
          times
          exit "$r"
       fi
    )
}

function commit_changes {
    local folder="$1"
    local msg="Modify poms to $VERSION in temp branch that was built on top of $BRANCH"

    pushd "$folder"
    git add -u
    git commit -m "$msg"
    git tag -f -a "$TAG_NAME" -m "$msg"
    popd
}

function delete_temp_branch {
    local folder="$1"
    local temp_branch="$2"
    echo "delete_temp_branch $temp_branch from folder $folder"

    pushd "$folder"
    git checkout -q "$TAG_NAME"
    git branch -D "$temp_branch"
    git push -f origin "$TAG_NAME"
    popd
}

# Clone xap-open and xap.
# Clean m2 from xap related directories.
# Create temporary local git branch.
# Rename poms.
# Call maven install.
# Commit changes.
# Create tag.
# Delete the temporary local branch.
# Push the tag
# Call maven deploy.
function release_xap {

    local xap_open_url="git@github.com:Gigaspaces/xap-open.git"
    local xap_url="git@github.com:Gigaspaces/xap.git"
    local temp_branch_name="$BRANCH-$VERSION"    
    local xap_open_folder="$(get_folder $xap_open_url)"
    local xap_folder="$(get_folder $xap_url)"
    echo "xap_folder is $xap_folder"

    clone "$xap_open_url" 
    clone "$xap_url"
   
    clean_m2 

    create_temp_branch "$temp_branch_name" "$xap_open_folder"
    create_temp_branch "$temp_branch_name" "$xap_folder"

    rename_poms "$xap_open_folder"
    rename_poms "$xap_folder"

    
    mvn_install "$xap_open_folder"
    mvn_install "$xap_folder"
    
    commit_changes "$xap_open_folder" 
    commit_changes "$xap_folder"

    delete_temp_branch "$xap_open_folder" "$temp_branch_name"
    delete_temp_branch "$xap_folder" "$temp_branch_name"

#    mvn_deploy "$xap_open_folder"
#    mvn_deploy "$xap_folder"

    times
}

release_xap 



