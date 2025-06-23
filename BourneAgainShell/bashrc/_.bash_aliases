# Aliases
alias grep='grep --color=auto'
alias ls='ls -CF --color=auto'
alias la='ls -A'
alias ll='ls -l'
alias ls='ls -F --color=auto'
alias diff='diff --color=auto'

# File Type Count
alias ftc='ls | rev | cut -d'.' -f1 | rev | sort | uniq -c'
