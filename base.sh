_omg_get_current_action() {
    local info="$(\git rev-parse --git-dir 2>/dev/null)"

    if [ -n "$info" ]; then
        local action
        if [ -f "$info/rebase-merge/interactive" ]; then
            action=${is_rebasing_interactively:-"rebase -i"}
        elif [ -d "$info/rebase-merge" ]; then
            action=${is_rebasing_merge:-"rebase -m"}
        else
            if [ -d "$info/rebase-apply" ]; then
                if [ -f "$info/rebase-apply/rebasing" ]; then
                    action=${is_rebasing:-"rebase"}
                elif [ -f "$info/rebase-apply/applying" ]; then
                    action=${is_applying_mailbox_patches:-"am"}
                else
                    action=${is_rebasing_mailbox_patches:-"am/rebase"}
                fi
            elif [ -f "$info/MERGE_HEAD" ]; then
                action=${is_merging:-"merge"}
            elif [ -f "$info/CHERRY_PICK_HEAD" ]; then
                action=${is_cherry_picking:-"cherry-pick"}
            elif [ -f "$info/BISECT_LOG" ]; then
                action=${is_bisecting:-"bisect"}
            fi
        fi

        if [[ -n $action ]]; then printf "%s" "${1-}$action${2-}"; fi
    fi
}

_omg_build_prompt() {
    local enabled=$(\git config --local --get oh-my-git.enabled)
    if [[ $enabled == false ]]; then
        exit
    fi

    local prompt=""

    # Git info
    local current_commit_hash=$(\git rev-parse HEAD 2>/dev/null)
    if [[ -n $current_commit_hash ]]; then local is_a_git_repo=true; fi

    if [[ $is_a_git_repo == true ]]; then
        local current_branch=$(\git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ $current_branch == 'HEAD' ]]; then local detached=true; fi

        if [[ -z "$(\git log --pretty=oneline -n1 2>/dev/null)" ]]; then
            local just_init=true
        else
            local upstream=$(\git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2>/dev/null)
            if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then local has_upstream=true; fi

            local git_status="$(\git status --porcelain 2>/dev/null)"
            local action="$(_omg_get_current_action)"

            if [[ $git_status =~ ($'\n'|^)\\? ]]; then local has_untracked_files=true; fi
            if [[ $git_status =~ ($'\n'|^).M ]]; then local has_modifications=true; fi
            if [[ $git_status =~ ($'\n'|^)M ]]; then local has_modifications_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)A ]]; then local has_adds=true; fi
            if [[ $git_status =~ ($'\n'|^).D ]]; then local has_deletions=true; fi
            if [[ $git_status =~ ($'\n'|^)D ]]; then local has_deletions_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)[MAD] && ! $git_status =~ ($'\n'|^).[MAD\?] ]]; then local ready_to_commit=true; fi

            local tag_at_current_commit=$(\git describe --exact-match --tags $current_commit_hash 2>/dev/null)
            if [[ -n $tag_at_current_commit ]]; then local is_on_a_tag=true; fi

            if [[ $has_upstream == true ]]; then
                local commits_diff="$(\git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2>/dev/null)"
                local commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
                local commits_behind=$(\grep -c "^>" <<< "$commits_diff")
            fi

            if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then local has_diverged=true; fi
            if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then local should_push=true; fi

            local will_rebase=$(\git config --get branch.${current_branch}.rebase 2>/dev/null)

            if [[ -n "$(\git stash list -n1 2>/dev/null)" ]]; then local has_stashes=true; fi
        fi
    fi

    echo "$(_omg_custom_build_prompt ${enabled:-true} ${is_a_git_repo:-false} ${just_init:-false} ${has_stashes:-false} ${has_untracked_files:-false} ${has_modifications:-false} ${has_deletions:-false} ${has_adds:-false} ${has_modifications_cached:-false} ${has_deletions_cached:-false} ${ready_to_commit:-false} ${detached:-false} ${is_on_a_tag:-false} ${has_upstream:-false} ${has_diverged:-false} ${should_push:-false} ${will_rebase:-false} ${current_commit_hash:-""} ${current_branch:-""} ${tag_at_current_commit:-""} ${commits_ahead:-""} ${commits_behind:-""} ${action:-""})"
}
