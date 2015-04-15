: ${omg_ungit_prompt:=$PS1}
: ${omg_second_line:=$PS1}

: ${omg_is_a_git_repo_symbol:='<U+E20E>'}
: ${omg_has_untracked_files_symbol:='<U+E157>'}        # <U+E224> <U+E1E9> <U+E802>  <U+E885>  <U+E1BB>  <U+E222> <U+E84E>  <U+E86F>  <U+F008>  ?  <U+E155>  <U+E157>
: ${omg_has_adds_symbol:='<U+E179>'}
: ${omg_has_deletions_symbol:='<U+E17A>'}
: ${omg_has_cached_deletions_symbol:='<U+E881>'}
: ${omg_has_modifications_symbol:='<U+E858>'}
: ${omg_has_cached_modifications_symbol:='<U+E813>'}
: ${omg_ready_to_commit_symbol:='<U+E19F>'}            # <U+E19F>  →
: ${omg_is_on_a_tag_symbol:='<U+E140>'}                # <U+E143>  <U+E140>
: ${omg_needs_to_merge_symbol:='ᄉ'}
: ${omg_detached_symbol:='<U+E221>'}
: ${omg_can_fast_forward_symbol:='<U+E1FE>'}
: ${omg_has_diverged_symbol:='<U+E822>'}               # <U+E822>  <U+E0A0>
: ${omg_not_tracked_branch_symbol:='<U+E205>'}
: ${omg_rebase_tracking_branch_symbol:='<U+E80B>'}     # <U+E21C>  <U+E80B>
: ${omg_merge_tracking_branch_symbol:='<U+E824>'}      #  <U+E824>
: ${omg_should_push_symbol:='<U+E80E>'}                # <U+E1EC>   <U+E80E>
: ${omg_has_stashes_symbol:='<U+E11D>'}

: ${omg_default_color_on:='\[\033[1;37m\]'}
: ${omg_default_color_off:='\[\033[0m\]'}
: ${omg_last_symbol_color:='\e[0;31m\e[40m'}

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
    local color=${3:-$omg_default_color_on}
    if [[ $flag == false ]]; then symbol=' '; fi

    echo -n "${color}${symbol}  "
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

    # foreground
    local black='\e[0;30m'
    local red='\e[0;31m'
    local green='\e[0;32m'
    local yellow='\e[0;33m'
    local blue='\e[0;34m'
    local purple='\e[0;35m'
    local cyan='\e[0;36m'
    local white='\e[0;37m'

    #background
    local background_black='\e[40m'
    local background_red='\e[41m'
    local background_green='\e[42m'
    local background_yellow='\e[43m'
    local background_blue='\e[44m'
    local background_purple='\e[45m'
    local background_cyan='\e[46m'
    local background_white='\e[47m'

    local reset='\e[0m'     # Text Reset]'

    local black_on_white="${black}${background_white}"
    local yellow_on_white="${yellow}${background_white}"
    local red_on_white="${red}${background_white}"
    local red_on_black="${red}${background_black}"
    local black_on_red="${black}${background_red}"
    local white_on_red="${white}${background_red}"
    local yellow_on_red="${yellow}${background_red}"

    # Flags
    local omg_default_color_on="${black_on_white}"

    if [[ $is_a_git_repo == true ]]; then
        # on filesystem
        prompt="${black_on_white} "
        prompt+=$(_omg_append $is_a_git_repo $omg_is_a_git_repo_symbol "${black_on_white}")
        prompt+=$(_omg_append $has_stashes $omg_has_stashes_symbol "${yellow_on_white}")

        prompt+=$(_omg_append $has_untracked_files $omg_has_untracked_files_symbol "${red_on_white}")
        prompt+=$(_omg_append $has_modifications $omg_has_modifications_symbol "${red_on_white}")
        prompt+=$(_omg_append $has_deletions $omg_has_deletions_symbol "${red_on_white}")

        # ready
        prompt+=$(_omg_append $has_adds $omg_has_adds_symbol "${black_on_white}")
        prompt+=$(_omg_append $has_modifications_cached $omg_has_cached_modifications_symbol "${black_on_white}")
        prompt+=$(_omg_append $has_deletions_cached $omg_has_cached_deletions_symbol "${black_on_white}")

        # next operation
        prompt+=$(_omg_append $ready_to_commit $omg_ready_to_commit_symbol "${red_on_white}")

        # where

        prompt="${prompt} ${white_on_red} ${black_on_red}"
        if [[ $detached == true ]]; then
            prompt+=$(_omg_append $detached $omg_detached_symbol "${white_on_red}")
            prompt+=$(_omg_append $detached "(${current_commit_hash:0:7})" "${black_on_red}")
        else
            if [[ $has_upstream == false ]]; then
                prompt+=$(_omg_append true "-- ${omg_not_tracked_branch_symbol} -- (${current_branch})" "${black_on_red}")
            else
                if [[ $will_rebase == true ]]; then
                    local type_of_upstream=$omg_rebase_tracking_branch_symbol
                else
                    local type_of_upstream=$omg_merge_tracking_branch_symbol
                fi

                if [[ $has_diverged == true ]]; then
                    prompt+=$(_omg_append true "-${commits_behind} ${omg_has_diverged_symbol} +${commits_ahead}" "${white_on_red}")
                else
                    if [[ $commits_behind -gt 0 ]]; then
                        prompt+=$(_omg_append true "-${commits_behind} ${white_on_red}${omg_can_fast_forward_symbol}${black_on_red} --" "${black_on_red}")
                    fi
                    if [[ $commits_ahead -gt 0 ]]; then
                        prompt+=$(_omg_append true "-- ${white_on_red}${omg_should_push_symbol}${black_on_red}  +${commits_ahead}" "${black_on_red}")
                    fi
                    if [[ $commits_ahead == 0 && $commits_behind == 0 ]]; then
                        prompt+=$(_omg_append true "--   --" "${black_on_red}")
                    fi
                fi
                prompt+=$(_omg_append true "(${current_branch} ${type_of_upstream} ${upstream//\/$current_branch/})" "${black_on_red}")
            fi
        fi
        prompt+=$(_omg_append ${is_on_a_tag} "${omg_is_on_a_tag_symbol} ${tag_at_current_commit}" "${black_on_red}")
        prompt+="${omg_last_symbol_color}${reset}\n"
        prompt+="${omg_second_line}"
    else
        prompt+="${omg_ungit_prompt}"
    fi

    echo "${prompt}"
}
