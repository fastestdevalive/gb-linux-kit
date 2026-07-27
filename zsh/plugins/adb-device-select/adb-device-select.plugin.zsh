# adb-device-select — interactive ADB device picker for zsh
#
# Commands:
#   select_device   pick a device and export ANDROID_SERIAL for the session
#   clear_device    unset the active device
#
# Prompt: add 'adb_device' to POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS in ~/.p10k.zsh
#
# Installation (oh-my-zsh):
#   ln -s ~/code/adb-device-select ~/.oh-my-zsh/custom/plugins/adb-device-select
#   # add 'adb-device-select' to plugins=() in ~/.zshrc

_adb_fetch_model() {
    adb -s "$1" shell getprop ro.product.model </dev/null 2>/dev/null | tr -d '\r\n'
}

_adb_sel_restore() {
    printf '\033[?25h'  # show cursor
    [[ -n $_ADB_SAVED_STTY ]] && stty "$_ADB_SAVED_STTY" 2>/dev/null
    unset _ADB_SAVED_STTY
}

select_device() {
    command -v adb &>/dev/null || { echo "adb: command not found"; return 1; }

    local -a serials labels
    while read -r serial state; do
        [[ $state == device ]] || continue
        local model=$(_adb_fetch_model "$serial")
        serials+=("$serial")
        labels+=("$serial  ${model:-unknown}")
    done < <(adb devices 2>/dev/null | tail -n +2 | grep -v '^[[:space:]]*$')

    if (( ${#serials[@]} == 0 )); then
        echo "No devices connected."
        return 1
    fi

    if [[ -n $ANDROID_SERIAL ]]; then
        printf "Current: \033[1;36m%s\033[0m  (%s)\n" "$ANDROID_SERIAL" "${_ADB_MODEL:-?}"
    else
        printf "Current: \033[2m(none)\033[0m\n"
    fi
    echo

    local chosen_serial chosen_model

    if command -v fzf &>/dev/null; then
        local selection
        selection=$(printf '%s\n' "${labels[@]}" | \
            fzf --prompt="ADB device > " --height=~12 --reverse --border)
        [[ -z $selection ]] && { echo "Cancelled."; return 0; }
        chosen_serial=${selection%% *}
        chosen_model=${selection#* }
        chosen_model=${chosen_model## }
    else
        local count=${#serials[@]}

        local sel=1 j
        for (( j=1; j<=count; j++ )); do
            [[ ${serials[$j]} == $ANDROID_SERIAL ]] && { sel=$j; break; }
        done

        _ADB_SAVED_STTY=$(stty -g 2>/dev/null)
        trap '_adb_sel_restore' INT
        stty -echo -icanon min 1 time 0 2>/dev/null
        printf '\033[?25l'

        printf "  \033[2m↑↓ navigate  ·  Enter select  ·  Esc/q cancel\033[0m\n"

        local first=1 cancelled=0 i k1 k2 k3
        while true; do
            (( first )) && first=0 || printf "\033[%dA" $count

            for (( i=1; i<=count; i++ )); do
                if (( i == sel )); then
                    printf "  \033[1;36m●\033[0m \033[1m%s\033[0m\n" "${labels[$i]}"
                else
                    printf "  \033[2m○ %s\033[0m\n" "${labels[$i]}"
                fi
            done

            if ! IFS= read -rk1 k1; then
                cancelled=1
                break
            fi

            if [[ $k1 == $'\033' ]]; then
                IFS= read -rk1 -t 0.1 k2 2>/dev/null || { cancelled=1; break; }
                if [[ $k2 == '[' ]]; then
                    IFS= read -rk1 -t 0.1 k3 2>/dev/null
                    case $k3 in
                        A) (( sel = sel > 1     ? sel - 1 : count )) ;;
                        B) (( sel = sel < count ? sel + 1 : 1     )) ;;
                    esac
                else
                    cancelled=1; break
                fi
            elif [[ $k1 == $'\r' || $k1 == $'\n' ]]; then
                break
            elif [[ $k1 == 'q' || $k1 == 'Q' ]]; then
                cancelled=1; break
            fi
        done

        printf "\033[%dA\033[0J" $((count + 1))
        _adb_sel_restore
        trap - INT

        if (( cancelled )); then
            echo "Cancelled."
            return 0
        fi

        chosen_serial="${serials[$sel]}"
        chosen_model="${labels[$sel]#* }"
        chosen_model="${chosen_model## }"
    fi

    export ANDROID_SERIAL="$chosen_serial"
    export _ADB_MODEL="${chosen_model}"
    printf "✓ \033[1;36m%s\033[0m  (%s)\n" "$ANDROID_SERIAL" "$_ADB_MODEL"
}

clear_device() {
    unset ANDROID_SERIAL _ADB_MODEL
    echo "Device cleared."
}

# ── Powerlevel10k segment ─────────────────────────────────────────────────────
# Add 'adb_device' to POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS in ~/.p10k.zsh to enable.
function prompt_adb_device() {
    [[ -n $ANDROID_SERIAL ]] || return
    local label="${ANDROID_SERIAL}"
    [[ -n $_ADB_MODEL ]] && label+=" · ${_ADB_MODEL}"
    p10k segment -f 6 -i $'\U1F4F1' -t "$label"
}

function instant_prompt_adb_device() {
    prompt_adb_device
}
