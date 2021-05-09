: ${OMG_MARK_STASH:='✸'}                  # ★ ✸
: ${OMG_MARK_UNTRACKED:='~'}              # ∪ ∙ ●
: ${OMG_MARK_MODIFICATIONS:='✎'}          # ✎
: ${OMG_MARK_DELETIONS:='−'}              # −
: ${OMG_MARK_ADDS:='+'}                   # ✚
: ${OMG_MARK_CACHED_MODIFICATIONS:='±'}   # ⌘ ∗
: ${OMG_MARK_CACHED_DELETIONS:='×'}       # ✖ ×
: ${OMG_MARK_COMMIT:='➜'}                 # ➜
: ${OMG_MARK_ACTION:='⚡'}                 # ‼ ⚡
: ${OMG_MARK_DETACHED:='#'}               # § ♯ #
: ${OMG_MARK_LOCAL:='▢'}                  # ▢
: ${OMG_MARK_FAST_FORWARD:='»'}           # »
: ${OMG_MARK_DIVERGED:='⌥'}               # ⌥
: ${OMG_MARK_PUSH:='⌅'}                   # ⌅
: ${OMG_MARK_MERGE:='۷'}                  # ≻ ۷ ۸ ٧ ٨
: ${OMG_MARK_REBASE:='↯'}                 # ↯
: ${OMG_MARK_TAG:='☗'}                    # ⌂ ☗
: ${OMG_COLOR_STASH:=$YELLOW}
: ${OMG_COLOR_UNTRACKED:=$BOLD_RED}
: ${OMG_COLOR_MODIFICATIONS:=$BOLD_RED}
: ${OMG_COLOR_DELETIONS:=$BOLD_RED}
: ${OMG_COLOR_ADDS:=$BOLD_BLUE}
: ${OMG_COLOR_CACHED_MODIFICATIONS:=$BOLD_BLUE}
: ${OMG_COLOR_CACHED_DELETIONS:=$BOLD_BLUE}
: ${OMG_COLOR_COMMIT:=$GREEN}
: ${OMG_COLOR_ACTION:=$RED}
: ${OMG_COLOR_DETACHED:=$RED}
: ${OMG_COLOR_MARK_DETACHED:=$BOLD_RED}
: ${OMG_COLOR_LOCAL:=$BLUE}
: ${OMG_COLOR_UPSTREAM:=$YELLOW}
: ${OMG_COLOR_COMMITS:=$YELLOW}
: ${OMG_COLOR_FAST_FORWARD:=$BOLD_BLUE}
: ${OMG_COLOR_DIVERGED:=$BOLD_RED}
: ${OMG_COLOR_PUSH:=$BOLD_GREEN}
: ${OMG_COLOR_MERGE:=$BOLD}
: ${OMG_COLOR_REBASE:=$BOLD}
: ${OMG_COLOR_TAG:=$PURPLE}

if [[ -n "$BASH_VERSION" ]]; then
    DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd -P)"
elif [[ -n "$ZSH_VERSION" ]]; then
    DIR="$(cd "${0%/*}" && pwd -P)"
fi
source $DIR/base.sh

_omg_append()
{
    local flag=$1
    local symbol=$2
    if [[ -z "$flag" || $flag == false ]]; then
        echo -n ""
    else
        echo -n "${symbol}"
    fi
}

_omg_append_sr()
{
    echo -n "$(_omg_append "$1" "$2 ")"
}

_omg_append_sl()
{
    echo -n "$(_omg_append "$1" " $2")"
}

_omg_custom_build_prompt()
{
    local enabled=${1}
    local is_a_git_repo=${2}
    local just_init=${3}
    local has_stashes=${4}
    local has_untracked_files=${5}
    local has_modifications=${6}
    local has_deletions=${7}
    local has_adds=${8}
    local has_modifications_cached=${9}
    local has_deletions_cached=${10}
    local ready_to_commit=${11}
    local detached=${12}
    local is_on_a_tag=${13}
    local has_upstream=${14}
    local has_diverged=${15}
    local should_push=${16}
    local will_rebase=${17}
    local current_commit_hash=${18}
    local current_branch=${19}
    local tag_at_current_commit=${20}
    local commits_ahead=${21}
    local commits_behind=${22}
    local action=${23}
    local prompt=""

    if [[ $is_a_git_repo == true ]]; then
        prompt+=$(_omg_append_sr $has_stashes "${OMG_COLOR_STASH}${OMG_MARK_STASH}${NO_COL}")

        prompt+=$(_omg_append_sr $has_untracked_files "${OMG_COLOR_UNTRACKED}${OMG_MARK_UNTRACKED}${NO_COL}")
        prompt+=$(_omg_append_sr $has_modifications "${OMG_COLOR_MODIFICATIONS}${OMG_MARK_MODIFICATIONS}${NO_COL}")
        prompt+=$(_omg_append_sr $has_deletions "${OMG_COLOR_DELETIONS}${OMG_MARK_DELETIONS}${NO_COL}")

        prompt+=$(_omg_append_sr $has_adds "${OMG_COLOR_ADDS}${OMG_MARK_ADDS}${NO_COL}")
        prompt+=$(_omg_append_sr $has_modifications_cached "${OMG_COLOR_CACHED_MODIFICATIONS}${OMG_MARK_CACHED_MODIFICATIONS}${NO_COL}")
        prompt+=$(_omg_append_sr $has_deletions_cached "${OMG_COLOR_CACHED_DELETIONS}${OMG_MARK_CACHED_DELETIONS}${NO_COL}")

        prompt+=$(_omg_append_sr $ready_to_commit "${OMG_COLOR_COMMIT}${OMG_MARK_COMMIT}${NO_COL}")
        prompt+=$(_omg_append_sr "$action" "${OMG_COLOR_ACTION}${OMG_MARK_ACTION} ${action}${NO_COL}")

        if [[ -n $prompt ]]; then
            prompt+="| "
        fi

        if [[ $detached == true ]]; then
            prompt+="${OMG_COLOR_DETACHED}(${NO_COL}"
            prompt+="${OMG_COLOR_MARK_DETACHED}${OMG_MARK_DETACHED}${NO_COL}"
            prompt+="${OMG_COLOR_DETACHED}${current_commit_hash:0:7})${NO_COL}"
        else
            if [[ $has_upstream == false ]]; then
                prompt+="${OMG_COLOR_LOCAL}(${current_branch})${NO_COL}"
            else
                if [[ $will_rebase == true ]]; then
                    local type_of_upstream="${OMG_COLOR_REBASE}${OMG_MARK_REBASE}${NO_COL}"
                else
                    local type_of_upstream="${OMG_COLOR_MERGE}${OMG_MARK_MERGE}${NO_COL}"
                fi

                if [[ $has_diverged == true ]]; then
                    prompt+="${OMG_COLOR_COMMITS}-${commits_behind}${NO_COL} "
                    prompt+="${OMG_COLOR_DIVERGED}${OMG_MARK_DIVERGED}${NO_COL} "
                    prompt+="${OMG_COLOR_COMMITS}+${commits_ahead}${NO_COL} "
                else
                    if [[ $commits_behind -gt 0 ]]; then
                        prompt+="${OMG_COLOR_COMMITS}-${commits_behind}${NO_COL} "
                        prompt+="${OMG_COLOR_FAST_FORWARD}${OMG_MARK_FAST_FORWARD}${NO_COL} "
                    fi
                    if [[ $commits_ahead -gt 0 ]]; then
                        prompt+="${OMG_COLOR_PUSH}${OMG_MARK_PUSH}${NO_COL} "
                        prompt+="${OMG_COLOR_COMMITS}+${commits_ahead}${NO_COL} "
                    fi
                fi
                prompt+="("
                prompt+="${OMG_COLOR_LOCAL}${current_branch}${NO_COL} "
                prompt+="${type_of_upstream} "
                prompt+="${OMG_COLOR_UPSTREAM}${upstream//\/$current_branch/}${NO_COL}"
                prompt+=")"
            fi
        fi
        prompt+=$(_omg_append_sl ${is_on_a_tag} "${OMG_COLOR_TAG}${OMG_MARK_TAG} ${tag_at_current_commit}${NO_COL}")
    else
        prompt=""
    fi

    echo "${prompt}"
}
