# bashics.bashrc - shell init file for bashics sourced from ~/.bashrc

bashics-semaphore() {
    [[ 1 -eq  1 ]]
}



# set_bashdebug_mode is a function that's useful for debugging shell commands+script in general:
[[ -f ~/.local/bin/bashics/set_bashdebug_mode ]] && source ~/.local/bin/bashics/set_bashdebug_mode
