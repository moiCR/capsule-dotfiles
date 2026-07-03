# Fish Shell Configuration

# Add user local bin to path
set -gx PATH "/home/moi/.local/bin" $PATH

# Disable greeting message
set -g fish_greeting ""

# Load dynamic theme colors from apply-theme.sh script
if test -f /home/moi/pro/dotfiles/fish/theme.fish
    source /home/moi/pro/dotfiles/fish/theme.fish
end

# Custom Aliases
alias c="clear"
alias q="exit"
alias ls="ls --color=auto"
alias ll="ls -lh --color=auto"
alias la="ls -A --color=auto"
alias grep="grep --color=auto"

# Git aliases
alias gst="git status"
alias gd="git diff"
alias gp="git push"
alias gl="git pull"
alias ga="git add"
alias gc="git commit"

# Custom minimal interactive prompt
if status is-interactive
    function fish_prompt
        # Save exit status of last command
        set -l last_status $status
        
        # Colors from theme
        set -l color_dir (set_color $fish_color_cwd)
        set -l color_git (set_color $fish_color_error)
        set -l color_normal (set_color normal)
        
        # Git integration
        set -l git_branch ""
        if command -v git >/dev/null 2>&1
            set -l branch (git branch --show-current 2>/dev/null)
            if test -n "$branch"
                set git_branch " $color_normalon $color_git$branch$color_normal"
            end
        end

        # Prompt symbol color: green/accent on success, red on failure
        set -l prompt_symbol " ❯"
        if test $last_status -ne 0
            set_color $fish_color_error --bold
        else
            set_color $fish_color_accent --bold
        end

        echo -n -s "$color_dir"(prompt_pwd)"$git_branch$prompt_symbol "
        set_color normal
    end
end
