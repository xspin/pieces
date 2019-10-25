#!/bin/bash

PIP=pip
# jupyter_dir=$(jupyter --data-dir)
jupyter_dir='/usr/local/share/jupyter'

echo "Install nbextensions ..."
$PIP install jupyter_contrib_nbextensions
jupyter contrib nbextension install

echo "Install jupyterthemes ..."
$PIP install jupyterthemes
jt -t onedork -f roboto -fs 10 -nfs 9  -vim -T

echo "Install vim_binding ..."
cd $jupyter_dir/nbextensions
git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding

echo "Enable extensions ..."
jupyter nbextension enable vim_binding/vim_binding
jupyter nbextension enable execute_time/ExecuteTime
jupyter nbextension enable codefolding/main
jupyter nbextension enable toggle_all_line_numbers/main
#jupyter nbextension enable code_prettify/code_prettify

echo "Restart jupyter ..."
pid=`ps x|grep jupyter-notebook|grep -v grep|awk '{print $1}'`
nohup bash -c "kill $pid && /usr/bin/start_jupyter.sh" > start_jupyter.log &