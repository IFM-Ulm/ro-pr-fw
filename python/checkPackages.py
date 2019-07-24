# -*- coding: utf-8 -*-
"""
Created on Mon Jun 17 12:02:48 2019

@author: hmandry
"""

from imp import find_module
import subprocess
import sys

NECESSARY_PACKAGES = {
        'numpy': 'numpy',
        'serial': 'pyserial',
        'matplotlib': 'matplotlib'
        };

def checkPythonmod(mod):
    try:
        op = find_module(mod)
        return True
    except ImportError:
        return False

def install(package):
    subprocess.call([sys.executable, "-m", "pip", "install", package]);

# Example
if __name__ == '__main__':    
        
    allThere = 1;
    for p in NECESSARY_PACKAGES.keys():
        if not checkPythonmod(p):
            allThere = 0;
            key = input('{} not installed, installing now? [y]/[n]'.format(NECESSARY_PACKAGES[p]))
            if key == 'y' or key == 'Y':
                install(NECESSARY_PACKAGES[p]);
                
    if allThere == 1:
        print('all necessary packages already installed');