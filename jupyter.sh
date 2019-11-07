#!/bin/bash

PIP=pip
# jupyter_dir=$(jupyter --data-dir)
jupyter_dir='/usr/local/share/jupyter'

echo -e "\033[32mInstall nbextensions ...\033[0m"
$PIP install jupyter_contrib_nbextensions
jupyter contrib nbextension install

echo -e "\033[32mInstall jupyterthemes ...\033[0m"
$PIP install jupyterthemes
jt -t onedork -f roboto -fs 10 -nfs 9 -vim -T

echo -e "\033[32mInstall vim_binding ...\033[0m"
cd $jupyter_dir/nbextensions
git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding

echo -e "\033[32mEnable extensions ...\033[0m"
jupyter nbextension enable vim_binding/vim_binding
jupyter nbextension enable execute_time/ExecuteTime
jupyter nbextension enable codefolding/main
jupyter nbextension enable toggle_all_line_numbers/main
#jupyter nbextension enable code_prettify/code_prettify
cd -

echo -e "\033[32mRestart jupyter ...\033[0m"
pid=`ps x|grep jupyter-notebook|grep -v grep|awk '{print $1}'`
nohup bash -c "kill $pid; /usr/bin/start_jupyter.sh" > /tmp/jupyter.log &