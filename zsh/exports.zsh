paths=(
    ~/.config/scripts
    ~/sdk/go1.24.1/bin
    /Users/kaynetik/go/bin
    /opt/homebrew/Cellar/openjdk/23.0.2/bin
)

export PATH="${(j.:.)paths}:$PATH"

export EDITOR=nvim
export JAVA_HOME='/opt/homebrew/Cellar/openjdk/23.0.2/'
alias java='/opt/homebrew/Cellar/openjdk/23.0.2/bin/java'
alias javac='/opt/homebrew/Cellar/openjdk/23.0.2/bin/javac'
