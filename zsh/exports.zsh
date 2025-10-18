paths=(
    ~/.config/scripts
    ~/sdk/go1.25.3/bin
    /Users/kaynetik/go/bin
    /opt/homebrew/Cellar/openjdk/25/bin
)

export PATH="${(j.:.)paths}:$PATH"

export EDITOR=nvim
export JAVA_HOME='/opt/homebrew/Cellar/openjdk/25/'
alias java='/opt/homebrew/Cellar/openjdk/25/bin/java'
alias javac='/opt/homebrew/Cellar/openjdk/25/bin/javac'
