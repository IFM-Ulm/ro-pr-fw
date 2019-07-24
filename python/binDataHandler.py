# -*- coding: utf-8 -*-
"""
Created on Thu Jun 13 09:37:49 2019

@author: hmandry

"""

import csv
import settings as SETTINGS
import numpy as np
import os

DELIM = os.sep;

class BinDataHandler(object):
    
    _STATE_TEMP_START = 0x00;
    _STATE_TEMP_END = 0x01;
    _STATE_RO = 0x02;
    _STATE_REF = 0x03;
    
    _FOLDER = 'output'
    
    _BYTES_TEMP = 2;
    _BYTES_RO = 4;
    
    
    def __init__(self, settings):
        self.__settings = settings;
        
        f1 = 'config_{}.csv'.format(settings.BRD_NAME);
        if os.path.isfile(f1):
            self.__config_csv = open(f1, mode='r');
        else:
            self.__config_csv = open('config.csv', mode='r');
        self.__config = csv.DictReader(self.__config_csv);
        
        self.__ref_data = np.zeros((settings.ROS_PER_BIN, settings.READOUTS),dtype=np.uint32);
        self.__ro_data = np.zeros((settings.ROS_PER_BIN, settings.READOUTS),dtype=np.uint32);
        
        if(settings.BRD_NAME == ''):
            prefix = '{}{}id{}'.format(self._FOLDER, DELIM, settings.BRD_ID);
        else:
            prefix = '{}{}{}_id{}'.format(self._FOLDER, DELIM, settings.BRD_NAME, settings.BRD_ID);
            
        csv_file = open('{}_ref_data.csv'.format(prefix), 'w', newline='', encoding='utf8');
        self.__writer_refData = csv.writer(csv_file);
        self.__file_refData = csv_file;
        
        csv_file = open('{}_ro_data.csv'.format(prefix), 'w', newline='', encoding='utf8');
        self.__writer_roData = csv.writer(csv_file);
        self.__file_roData = csv_file;
        
        csv_file = open('{}_ro_x.csv'.format(prefix), 'w', newline='', encoding='utf8');
        self.__writer_roX = csv.writer(csv_file);
        self.__file_roX = csv_file;
        
        csv_file = open('{}_ro_y.csv'.format(prefix), 'w', newline='', encoding='utf8');
        self.__writer_roY = csv.writer(csv_file);
        self.__file_roY = csv_file;
        
        self.__roIndex = 0;
        self.__readoutIndex = 0;
        
        self.__bytesToRead = self._BYTES_TEMP;
        self.__state = self._STATE_TEMP_START;
        
        self.__roValid = np.zeros((settings.ROS_PER_BIN),dtype=np.int);

        self.__bins = 0;
        self.__binsMax = 0;
        
        self.__handleConfig();
        
        
    def setBins(self, bins):
        self.__binsMax = bins;
        
    def getBytesToRead(self):
        return self.__bytesToRead;
    
    def handleData(self, dataBytes):
#        print('state = {:02d}; ro_index = {:02d}; readout_idx = {:03d}'.format(self.__state, self.__roIndex, self.__readoutIndex));
        if(self.__state <= self._STATE_TEMP_END):   #temperature not saved
            if(self.__state == self._STATE_TEMP_END):
                self.__bytesToRead = self._BYTES_RO;
            self.__state += 1;
            return;
            
        data = int.from_bytes(dataBytes, 'little');            
        if(self.__settings.MODE == SETTINGS.MODE_PAR):
            self.__handleDataPar(data);
        else:
            self.__handleDataSeq(data);
            
    def closeFiles(self):
        self.__config_csv.close();
        self.__file_refData.close();
        self.__file_roData.close();
        self.__file_roX.close();
        self.__file_roY.close();
    

    def __handleDataPar(self, data):
        if(self.__state == self._STATE_RO):
            self.__ro_data[self.__roIndex][self.__readoutIndex] = data;
            self.__roIndex += 1;
            if(self.__roIndex == self.__settings.ROS_PER_BIN):
                self.__state = self._STATE_REF;
                self.__roIndex = 0;
        elif(self.__state == self._STATE_REF):
            for ro in range(self.__settings.ROS_PER_BIN):
                self.__ref_data[ro][self.__readoutIndex] = data;
            
            self.__state = self._STATE_RO;
            self.__readoutIndex += 1;
            if(self.__readoutIndex == self.__settings.READOUTS):
               self.__readoutIndex = 0;
               self.__state = self._STATE_TEMP_START;
               self.__writeFiles();
               self.__handleConfig();
               self.__bytesToRead = self._BYTES_TEMP;
        
        
    def __handleDataSeq(self, data):
        if(self.__state == self._STATE_RO):
            self.__ro_data[self.__roIndex][self.__readoutIndex] = data;
            self.__state = self._STATE_REF;
        elif(self.__state == self._STATE_REF):
            self.__ref_data[self.__roIndex][self.__readoutIndex] = data;
            
            self.__state = self._STATE_RO;
            
            self.__roIndex += 1;
            if(self.__roIndex == self.__settings.ROS_PER_BIN):
               self.__roIndex = 0;
               self.__readoutIndex += 1;
            if(self.__readoutIndex == self.__settings.READOUTS):
               self.__readoutIndex = 0;
               self.__roIndex = 0;
               self.__state = self._STATE_TEMP_START;
               self.__writeFiles();
               self.__handleConfig();
               self.__bytesToRead = self._BYTES_TEMP;
            

            
    def __handleConfig(self):
        resString = '';
        try:
            for i in range(self.__settings.ROS_PER_BIN):
                row = next(self.__config);
                self.__roValid[i] = int(row['valid']);
                if self.__roValid[i]:
                    self.__writer_roX.writerow([int(row['x'])]);
                    self.__writer_roY.writerow([int(row['y'])]);
            
            if (self.__binsMax > 0):
                resString = 'binary {:d} of {:d} ({:f} %) done'.format(self.__bins, self.__binsMax,(self.__bins/self.__binsMax*100));
                print(resString);
            self.__bins += 1;
        except StopIteration:
#            print('end of config');
            self.__roValid = np.zeros((self.__settings.ROS_PER_BIN),dtype=np.int);
        return resString;
            
            
    def __writeFiles(self):
        for i in range(self.__settings.ROS_PER_BIN):
            if(self.__roValid[i]):
                self.__writer_roData.writerow(self.__ro_data[i]);
                self.__writer_refData.writerow(self.__ref_data[i]);
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            