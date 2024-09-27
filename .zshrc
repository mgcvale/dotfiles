# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_QPA_PLATFORM_THEME=qt6ct
export PATH_TO_FX=/usr/lib/jvm/javafx-sdk-21.0.3/lib


ZSH_THEME="jreese"
ZSH_THEME_RANDOM_CANDIDATES=(
   "agnoster"
   "gnzh" 
)

plugins=( 
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

### From this line is for pywal-colors
# Import colorscheme from 'wal' asynchronously
# &   # Run the process in the background.
# ( ) # Hide shell job control messages.
# Not supported in the "fish" shell.
# cat ~/.cache/wal/sequences & > /dev/null
# Alternative (blocks terminal for 0-3ms)
cat ~/.cache/wal/sequences

# To add support for TTYs this line can be optionally added.
#source ~/.cache/wal/colors-tty.sh

clear
