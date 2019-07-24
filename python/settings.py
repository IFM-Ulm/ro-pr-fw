# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 13:13:05 2019

@author: hmandry
"""

import csv
import os

MODE_PAR = 0x01
MODE_SEQ = 0x00

TIME_1_US = 0;
TIME_10_US = 1;
TIME_100_US = 2;
TIME_1_MS = 3;
TIME_30_US = 4;
TIME_50_US = 5;
# TIME_1_S = 6;
TIME_70_US = 7;

TIMES = {
    '1 us': TIME_1_US,
    '10 us': TIME_10_US,
    '30 us': TIME_30_US,
    '50 us': TIME_50_US,
    '70 us': TIME_70_US,
    '100 us': TIME_100_US,
    '1 ms': TIME_1_MS
};
        
MODES = {
    'parallel': MODE_PAR,
    'sequential': MODE_SEQ        
};

class Settings(object):

    # connection
    PORT = 'COM14';
    BAUDRATE = 115200;
    
    # measurement
    MODE = MODE_PAR;    #u8
    READOUTS = 100;    #u32
    TIME = TIME_1_US;  #u32
    HEATUP = 0;         #u32
    COOLDOWN = 0;       #u32
    REPETITIONS = 0;       #u32
    
    # 
    BRD_ID = '01';
    BRD_NAME = '';
    
    def __init__(self):
        
        self.ROS_PER_BIN = 0;
        self.NR_BIN_T1 = 0;
        self.NR_BIN_T2 = 0;
        
        
    def updateSettings(self):
        f1 = 'params_{}.csv'.format(self.BRD_NAME);
        if os.path.isfile(f1):
            params_csv = open(f1, mode='r');
        else:
            params_csv = open('params.csv', mode='r');
        
        csv_reader = csv.reader(params_csv);
        next(csv_reader); #skip header
        row = next(csv_reader);
        self.ROS_PER_BIN = int(row[0]);
        row = next(csv_reader);
        self.NR_BIN_T1 = int(row[0]);
        row = next(csv_reader);
        self.NR_BIN_T2 = int(row[0]);
        params_csv.close();