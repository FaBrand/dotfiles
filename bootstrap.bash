#!/bin/bash

function exists() {
  command -v $1 >/dev/null 2>&1
}

function setup_catkin_aliases() {
    export CATKIN_ALIASES=$HOME/.config/catkin/verb_aliases/00-default-aliases.yaml
    if [ -e "$CATKIN_ALIASES" ]; then
        echo 'Copying catkin aliases'
        cp ./catkin_aliases/42-default-aliases.yaml ~/.config/catkin/verb_aliases/
    fi
}

function install_fzf() {
# Install a fuzzy file finder for the command line (https://github.com/junegunn/fzf)
which fzf > /dev/null
    if [[ $? -eq 1 ]]; then
        echo 'Installing fzf'
        fzf_install_dir=~/.fzf
        git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_install_dir
        cd $fzf_install_dir
        ./install --all
        cd -
    fi
}

function install_oh_my_zsh() {
    export ZSH=$HOME/.oh-my-zsh

    if [ ! -e "$ZSH" ]; then
        echo 'Install OhMyZsh'
        # install zsh
        # This is the original repository
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
        # Patch with the fix for the solarized shell
        rm -rf $ZSH
        # Apply my patches for the color config (Probably not necessary everywhere
        git clone https://github.com/FaBrand/oh-my-zsh.git $ZSH
    else
        echo 'OhMyZsh already installed'
    fi
}

function install_powerline_fonts() {
    echo 'Install powerline fonts'
    local POWERLINE_URL='https://github.com/powerline/powerline/raw/develop/font'
    local POWERLINE_SYMBOLS_FILE='PowerlineSymbols.otf'
    local POWERLINE_SYMBOLS_CONF='10-powerline-symbols.conf'

    if [[ ! -e ~/.fonts/$POWERLINE_SYMBOLS_FILE ]]; then
        curl -fsSL $POWERLINE_URL/$POWERLINE_SYMBOLS_FILE -o /tmp/$POWERLINE_SYMBOLS_FILE
        mkdir ~/.fonts 2> /dev/null
        mv /tmp/$POWERLINE_SYMBOLS_FILE ~/.fonts/$POWERLINE_SYMBOLS_FILE
        fc-cache -vf ~/.fonts/
    fi

    if [[ ! -e ~/.config/fontconfig/conf.d/$POWERLINE_SYMBOLS_CONF ]]; then
        curl -fsSL $POWERLINE_URL/$POWERLINE_SYMBOLS_CONF -o /tmp/$POWERLINE_SYMBOLS_CONF
        mkdir -p ~/.config/fontconfig/conf.d 2> /dev/null
        mv /tmp/$POWERLINE_SYMBOLS_CONF ~/.config/fontconfig/conf.d/$POWERLINE_SYMBOLS_CONF
    fi
}

function install_solarized_color_scheme() {
    local DIR=~/.solarized
    if ! exists dconf; then
        echo 'Package dconf-cli required for solarized colors!'
        return -1
    elif [ ! -d $DIR ]; then
        read -p "Have you already defined a new profile in your Terminal preferences e.g. 'SolDark'? If not add it now and continue by pressing the return key..."
        echo Install solarized color scheme
        git clone https://github.com/Anthony25/gnome-terminal-colors-solarized.git $DIR
        cd ~/ && $DIR/install.sh --install-dircolors
        cd -
    else
        echo 'Solarized theme already installed'
    fi
}

function copy_to_home() {
    read -p "Do you want to copy the dotfiles to your home reposory? (This may overwrite some files) Are you sure? (y/n) " -n 1;
    echo "";
    if [[ $REPLY =~ ^[Yy]$ ]]; then

        # never overwrite existing .gitconfig
        if [ ! -f ~/.gitconfig ]; then
            cp .gitconfig ~/.gitconfig
        fi

        # never overwrite existing .vimrc.local
        if [ ! -f ~/.vimrc.local ]; then
            cp .vimrc.local ~/.vimrc.local
        fi

        # Backup a possibly existing zshrc file
        if [ -f ~/.zshrc ]; then
            echo "Created backup file from existing zshrc file"
            cp ~/.zshrc ~/backup.zshrc
        fi

        rsync --exclude '.git/' \
            --exclude 'bootstrap.bash' \
            --exclude '.gitconfig' \
            --exclude '.vimrc.local' \
            --exclude 'README.md' \
            --exclude 'catkin_aliases/*' \
            -avh --no-perms . ~;
    fi
}

function install_vim_huge_configuration() {
    # Check vim installation and perform changes if necessary
    dpkg -s vim-tiny > /dev/null
    if [ ! $? -eq 1 ]; then
        echo 'Removing vim-tiny installation'
        sudo -s apt-get -qq remove vim-tiny
    fi

    dpkg -s vim-gnome > /dev/null
    if [ $? -eq 1 ]; then
        echo 'Installing vim (huge config)'
        sudo -s apt-get install -qq vim-gnome
    else
        echo 'vim gnome already installed'
    fi
}

function install_packages() {
    # Install usefull packages
    packages=(
        build-essential
        clang-format
        clang-tidy
        cmake
        cppcheck
        curl
        dconf-cli
        exuberant-ctags
        git
        meld
        python-dev
        python3-dev
        rsync
        silversearcher-ag
        taskwarrior
        tmux
        tmuxinator
        tree
        valgrind
        xsel
        zsh
    )

    echo 'Performing apt-get update'
    sudo -s apt-get -qq update

    echo "Installing items"
    echo ${packages[*]} | xargs sudo -s apt install --assume-yes
}


function install_full() {
    copy_to_home
    install_packages
    install_oh_my_zsh
    install_vim_huge_configuration
    install_powerline_fonts
    install_solarized_color_scheme
    install_fzf
    setup_catkin_aliases
}

install_full
