#Add the following lines to your .bashrc for autojump to work

export PROMPT_COMMAND='autojump.py -a "$(pwd -P)"'
alias jstat="autojump.py --stat"
function j { new_path=$(autojump.py $@);if [ -n "$new_path" ]; then echo -e "\\033[31m${new_path}\\033[0m"; echo; cd "$new_path";ls -ltr --color=yes| tail -n 60;fi }