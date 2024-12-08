paths=(
    ~/.config/scripts
    ~/sdk/go1.23.3/bin
)

export PATH="${(j.:.)paths}:$PATH"
