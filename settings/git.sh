# good experience with git.
alias ga='git add'
alias gai='git add -i'
alias gap='git add -p'
alias gau='git add -u'
alias gan='git_add_new_files'
alias gb='git branch'
alias gc='git commit'
alias gca='git commit -a'
alias gd='git diff'
alias gdt='git difftool'
alias gdc='git diff --color'
alias gdr='git_recursive_diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gfr='git fetch;git rebase;'
alias gm='git merge'
alias ggrep='git grep'
alias glp='git log -p'
alias go='git checkout'
alias gr='git rebase'
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias gg='git lg'
alias gs='git status'
alias gss='git status --short'
alias gsr='git_recursive_status'
alias gsfrs='git stash;git fetch;git rebase;git stash pop;'
alias gsp='git stash pop'
alias gcp='git cherry-pick'
alias gcpc='git cherry-pick --continue'
alias gcpa='git cherry-pick --abort'
alias cdsubmodule='GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && [[ -n "$GIT_ROOT" ]] && [[ -f "$GIT_ROOT/.gitmodules" ]] && realpath=$(awk -F= "/path =/ {print substr(\$2, 2)}" "$GIT_ROOT/.gitmodules") && cd "$GIT_ROOT/$realpath"'

function gom() {
    git ls-files -m $*|while read -r file;
    do
        git checkout "$file";
    done
}

function gdv() {
    if [[ -n "$1" ]] ; then
        git diff "$*"|gvim -R -
    else
        git diff|gvim -R -
    fi
}

function git_add_new_files() {
    git status --short "$*"|grep '^??'|cut -c 4-|while read -r file;do git add "$file";done
}

function deleteNewFiles() {
    git status --short "$*"|grep '^??'|cut -c 4-|while read -r file;do rm -rf "$file";done
}

function editConfilicts() {
    gvim $(git status --short|grep ^UU|awk '{print $2}')
}

function showConfilictsInRevesion() {
    if [[ -n "$1" ]] ; then
        echo "will show $*"
    else
        echo "you must specify a revision."
        kill -INT $$
    fi
    git status --short|grep ^UU|awk '{print $2}'|while read -r file;
    do
        echo "file:$file in $*"
        git show "$*:$file"
    done
}

function showModifiedFilesInRevesion() {
    if [[ -n "$1" ]] ; then
        echo "will show $*"
    else
        echo "you must specify a revision."
        kill -INT $$
    fi
    git status --short|grep '^ M'|awk '{print $2}'|while read -r file;
    do
        echo "file:$file in $*"
        git show "$*:$file"
    done
}

# copy lxf's scripts.
function __cherry_pick_help() {
    echo "Usage: git_cherry_pick_with_user [-n|--no-date] <commit>..."
}

function __cherry_pick_single_commit() {
    nodate="$1"
    commit="$2"
    committer="$(git log --pretty=fuller -1 $commit|grep 'Commit:'|sed 's/Commit: *//')"
    name="$(echo $committer|sed 's/\(.*\) <.*/\1/')"
    email="$(echo $committer|sed 's/[^<]*//')"
    date="$(git log --pretty=fuller -1 $commit|grep CommitDate|sed 's/CommitDate: *//')"
    echo "Picking $commit $name|$email|$date"
    oldName="$(git config user.name)"
    oldEmail="$(git config user.email)"
    git config user.name "$name"
    git config user.email "$email"
    if [[ "$nodate" == "0" ]]; then
        GIT_AUTHOR_DATE="$date" && GIT_COMMITTER_DATE="$date" && git cherry-pick "$commit"
    else
        git cherry-pick "$commit"
    fi
    git config user.name "$oldName"
    git config user.email "$oldEmail"
}

function git_cherry_pick_with_user() {
    nodate="0"
    case "$1" in
    -h|--help)
        __cherry_pick_help
        ;;
    -n|--no-date)
        nodate="1"
        shift
        ;;
    *)
    ;;
    esac
    if [[ "$1" == "" ]]; then
        __cherry_pick_help
    else
    while [[ $# -gt 0 ]]; do
        commits="$1"
        if [[ -n $(echo "$commits"|grep "\.\.") ]]; then
            for commit in $(git rev-list --reverse "$commits"); do
                __cherry_pick_single_commit $nodate "$commit"
            done
        else # Single commit.
            __cherry_pick_single_commit $nodate "$commits"
        fi
        shift
    done
    fi
}

function git_recursive_status() {
    current=$(git status --short)
    if [[ -n $current ]];
    then
        pwd
        git status --short
    fi
    if [[ -f .gitmodules ]];
    then
        cat .gitmodules|awk -F= '/path = /{print $2}'|while read dir;
        do
            (cd $dir;git_recursive_status)
        done
    fi
}

function git_show_modified_file_names() {
    git ls-files -m "$*"
}

function git_recursive_diff() {
    current=$(git status --short)
    if [[ -n $current ]];
    then
        pwd
        if [[ -n "$*" ]];
        then
            git diff "$*"
        else
            git diff
        fi
    fi
    if [[ -f .gitmodules ]];
    then
        cat .gitmodules|awk -F= '/path = /{print $2}'|while read dir;
        do
            (cd $dir;git_recursive_diff "$*")
        done
    fi
}

function git_svn_clone_from_branch_base() {
    url="$*"
    logs="$(svn log --stop-on-copy $url)"
    revision="$(echo $logs|awk -F\| '/^r[0-9]+/{print $ 1}'|tail -n 1|sed 's/r//'|sed 's/ //g')"
    echo "cloning from $revision for $url"
    git svn clone -r"$revision":HEAD "$url"
}

function git_svn_clone_from_last_10() {
    url="$*"
    logs="$(svn log -l 10 $url)"
    revision="$(echo $logs|awk -F\| '/^r[0-9]+/{print $ 1}'|tail -n 1|sed 's/r//'|sed 's/ //g')"
    echo "cloning from $revision for $url"
    git svn clone -r"$revision":HEAD "$url"
}

function git_svn_clone_from_last_20() {
    url="$*"
    logs="$(svn log -l 20 $url)"
    revision="$(echo $logs|awk -F\| '/^r[0-9]+/{print $ 1}'|tail -n 1|sed 's/r//'|sed 's/ //g')"
    echo "cloning from $revision for $url"
    git svn clone -r"$revision":HEAD "$url"
}

function git_svn_clone_from_last_50() {
    url="$*"
    logs="$(svn log -l 50 $url)"
    revision="$(echo $logs|awk -F\| '/^r[0-9]+/{print $ 1}'|tail -n 1|sed 's/r//'|sed 's/ //g')"
    echo "cloning from $revision for $url"
    git svn clone -r"$revision":HEAD "$url"
}

function git_svn_clone_from_last_100() {
    url="$*"
    logs="$(svn log -l 100 $url)"
    revision="$(echo $logs|awk -F\| '/^r[0-9]+/{print $ 1}'|tail -n 1|sed 's/r//'|sed 's/ //g')"
    echo "cloning from $revision for $url"
    git svn clone -r"$revision":HEAD "$url"
}

function up() {
    find . -d -name .git|while read -r type;
    do
        if [[ -n "$type" ]]; then
            (cd "$type/.." ;
            [[ -n "$(git config remote.origin.url)" ]] && git fetch
            grep -c "svn-remote" ".git/config" 1>/dev/null 2>&1 && git svn fetch && git branch -f svn git-svn
            )
        fi
    done
}

function kgitx() {
    local pids=$(ps -A|grep GitX|grep -v grep|awk '{print $1}')
    echo "$pids"|while read -r pid;
    do
        if [[ -n "$pid" ]]; then
            kill -9 $pid
        fi
    done
    gitx "$*"
}