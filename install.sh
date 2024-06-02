#!/bin/bash


# define variables containing escape sequences for ANSI color codes
# Documentation: https://gkarthiks.github.io/quick-commands-cheat-sheet/bash_command.html
Black=''
DarkGray=''
LightGray=''
Red=''
LightRed=''
Green=''
LightGreen=''
Brown=''
Yellow=''
Blue=''
LightBlue=''
Purple=''
LightPurple=''
Cyan=''
LightCyan=''
White=''
NoColor=''

# checks if file descriptor 1 (stdout) is associated with a terminal
if [[ -t 1 ]]; then
    Black='\033[0;30m'
    DarkGray='\033[1;30m'
    LightGray='\033[0;37m'
    Red='\033[0;31m'
    LightRed='\033[1;31m'
    Green='\033[0;32m'
    LightGreen='\033[1;32m'
    Brown='\033[0;33m'
    Yellow='\033[1;33m'
    Blue='\033[0;34m'
    LightBlue='\033[1;34m'
    Purple='\033[0;35m'
    LightPurple='\033[1;35m'
    Cyan='\033[0;36m'
    LightCyan='\033[1;36m'
    White='\033[1;37m'
    NoColor='\033[0m'
fi

success() {
    echo -e "${Green}$@ ${NoColor}"
}

info() {
    echo -e "${White}$@ ${NoColor}"
}

error() {
    echo -e "${Red}error${NoColor}:" "$@" >&2
    exit 1
}

if ! command -v curl &> /dev/null
then
    echo "curl is not installed."
    read -p "Do you want to install curl? (y/n): " choice
    case "$choice" in
        y|Y ) 
            # Install curl
            sudo pacman -S curl --noconfirm
            ;;
        n|N ) 
            echo "curl is required for ezcommits. Exiting..."
            exit 1
            ;;
        * ) 
            echo "Invalid choice. Please enter 'y' or 'n'."
            exit 1
            ;;
    esac
else
    echo "curl is installed."
fi


success " ______ ___________ ____  __  __ __  __ _____ _______ _____  "
success " |  ____|___  / ____/ __ \|  \/  |  \/  |_   _|__   __/ ____|"
success " | |__     / / |   | |  | | \  / | \  / | | |    | | | (___  "
success " |  __|   / /| |   | |  | | |\/| | |\/| | | |    | |  \___ \ "
success " | |____ / /_| |___| |__| | |  | | |  | |_| |_   | |  ____) |"
success " |______/_____\_____\____/|_|  |_|_|  |_|_____|  |_| |_____/ "
success "                                                             "

echo -e "${Yellow}EZCommits${NoColor} helps you to write and maintain proper commit messages."

if ! command -v gum &> /dev/null
then
    echo "gum is not installed."
    read -p "Do you want to install gum? (y/n): " choice
    case "$choice" in
        y|Y ) 
            sudo pacman -S gum --noconfirm
            ;;
        n|N ) 
            echo "gum is required for EZCommits. Exiting..."
            exit 1
            ;;
        * ) 
            echo "Invalid choice. Please enter 'y' or 'n'."
            exit 1
            ;;
    esac
else
    echo "gum is installed."
fi

echo 
info "Installing EZCommits..."

ezcommits_url=https://raw.githubusercontent.com/iconized/ezcommits/master/ezcommits

install_env=EZCOMMITS_INSTALL
bin_env=\$$install_env/bin

install_dir=${!install_env:-$HOME/.ezcommits}
bin_dir=$install_dir/bin
sh=$bin_dir/ezcommits


if [[ ! -d $bin_dir ]]; then
    mkdir -p "$bin_dir" ||
        error -e "${Red}Failed${NoColor} to create install directory \"$bin_dir\""
fi

curl -fsSL --fail --location --output "$sh" "$ezcommits_url" ||
  error "Failed to download commit from \"$ezcommits_url\""

gum spin --spinner dot --title "Downloading EZCommits..." --spinner.foreground="80" -- sleep 5  && echo -e "EZCommits version $LATEST_RELEASE downloaded. ${Cyan}https://github.com/iconized/ezcommits${NoColor}"

gum spin --spinner dot --title "Setting Up..." --spinner.foreground="80" -- sleep 3


chmod +x "$sh" ||
    error 'Failed to set permissions on Ezcommits executable'

tildify() {
    if [[ $1 = $HOME/* ]]; then
        local replacement=\~/

        echo "${1/$HOME\//$replacement}"
    else
        echo "$1"
    fi
}


echo
success "EZCommits was installed successfully to $Green$(tildify "$sh")"

refresh_command=''

tilde_bin_dir=$(tildify "$bin_dir")
quoted_install_dir=\"${install_dir//\"/\\\"}\"

if [[ $quoted_install_dir = \"$HOME/* ]]; then
    quoted_install_dir=${quoted_install_dir/$HOME\//\$HOME/}
fi

echo

case $(basename "$SHELL") in
fish)
    commands=(
        "set --export $install_env $quoted_install_dir"
        "set --export PATH $bin_env \$PATH"
    )

    fish_config=$HOME/.config/fish/config.fish
    tilde_fish_config=$(tildify "$fish_config")

    if [[ -w $fish_config ]]; then
        {
            echo -e '\n# ezcommits'

            for command in "${commands[@]}"; do
                echo "$command"
            done
        } >>"$fish_config"

        info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_fish_config\""

        refresh_command="source $tilde_fish_config"
    else
        echo "Manually add the directory to $tilde_fish_config (or similar):"

        for command in "${commands[@]}"; do
            info "  $command"
        done
    fi

   ;;
zsh)
    commands=(
        "export $install_env=$quoted_install_dir"
        "export PATH=\"$bin_env:\$PATH\""
    )

    zsh_config=$HOME/.zshrc
    tilde_zsh_config=$(tildify "$zsh_config")

    if [[ -w $zsh_config ]]; then
        {
            echo -e '\n# ezcommits'

            for command in "${commands[@]}"; do
                echo "$command"
            done
        } >>"$zsh_config"

        info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_zsh_config\""

        refresh_command="exec $SHELL"
    else
        echo "Manually add the directory to $tilde_zsh_config (or similar):"

        for command in "${commands[@]}"; do
            info "  $command"
        done
    fi
    ;;
*)
    echo -e "Manually add the directory to ${Yellow}~/.bashrc${NoColor} (or similar):"
    info "  export $install_env=$quoted_install_dir"
    info "  export PATH=\"$bin_env:\$PATH\""
    ;;
esac


echo
echo -e "To get started, go to your project folder and type ${Yellow}ezcommits${NoColor} to commit changes."
echo

if [[ $refresh_command ]]; then
    info " $refresh_command"
fi