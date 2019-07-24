# -*- coding: utf-8 -*-
"""
Created on Wed Jun 19 12:44:14 2019

@author: hmandry
"""

import numpy as np
import matplotlib.pyplot as plt
import tkinter as tk
from tkinter import Label
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

import os
import csv

DELIM = os.sep;
FOLDER = 'output'

FIG_SIZE_X = 5;
FIG_SIZE_Y = 4;
FIG_DPI = 200;


#https://matplotlib.org/3.1.0/users/navigation_toolbar.html

class VisualizerHeatMap(object):
    
    def __init__(self, settings):
        
        window = tk.Tk();
        
        windows = [window];
        
        prefix = self.__getPrefix(settings.BRD_NAME, settings.BRD_ID);
        f1 = '{}_ro_data.csv'.format(prefix);
        if os.path.isfile(f1):
            (ro, x, y) = self.__loadData(settings.BRD_NAME, settings.BRD_ID);
            dataMean = self.__getMean(ro,x,y);
            figure = self.__plotHeatmap(dataMean);
            
            if settings.BRD_NAME == '':
                window.title("{} mean".format(settings.BRD_ID));
            else:
                window.title("{} {} mean".format(settings.BRD_NAME, settings.BRD_ID));
                    
            chart_type = FigureCanvasTkAgg(figure, window);
            chart_type.get_tk_widget().pack();
            
            window2 = tk.Tk();
            windows.append(window2);
            dataStd = self.__getStd(ro,x,y);
            figure2 = self.__plotHeatmap(dataStd);
            
            if settings.BRD_NAME == '':
                window2.title("{} std".format(settings.BRD_ID));
            else:
                window2.title("{} {} std".format(settings.BRD_NAME, settings.BRD_ID));
                    
            chart_type2 = FigureCanvasTkAgg(figure2, window2);
            chart_type2.get_tk_widget().pack();
            
            
            
            
            window3 = tk.Tk();
            windows.append(window3);
            figure3 = self.__plotRos(ro);
            
            if settings.BRD_NAME == '':
                window3.title("{} ROs".format(settings.BRD_ID));
            else:
                window3.title("{} {} ROs".format(settings.BRD_NAME, settings.BRD_ID));
                    
            chart_type3 = FigureCanvasTkAgg(figure3, window3);
            chart_type3.get_tk_widget().pack();
            
                                    
        else:
            labelError = Label(window, text="no board data for {} found".format(prefix), width=40, bg='red');
            labelError.pack();
        
        self.__windows = windows;

        for w in windows:
            w.update();
        
        
    def getWindowList(self):
        return self.__windows;
        
        
    def __loadData(self, brdName, brdId):

        prefix = self.__getPrefix(brdName, brdId);
        files = ['_ro_data.csv', '_ro_x.csv', '_ro_y.csv'];
        res = [];
        
        for f in files:
            csv_file = open('{}{}'.format(prefix,f), 'r', newline='', encoding='utf8');
            csv_data = csv.reader(csv_file);
            data = next(csv_data);
            try:
                while 1:
                    row = next(csv_data);
                    data=np.vstack([data, row]);
            except StopIteration:
                print("loaded {}".format(f));
                pass;
                
            csv_file.close();
            res.append(data);
            
        ro = np.array(res[0]).astype(np.int32);
        x = np.array(res[1]).astype(np.int32);
        y = np.array(res[2]).astype(np.int32);
                
        return (ro, x, y);
    
    def __getMean(self, ro, x, y):
        data = np.empty((np.amax(y)+1, np.amax(x)+1));
        data[:] = np.nan;
        
        m = np.mean(ro,axis=1);

        for i in range(len(x)):
            data[y.item((i))][x.item((i))] = m.item((i));
            
        return data;
        
        
    def __getStd(self, ro, x, y):
        data = np.empty((np.amax(y)+1, np.amax(x)+1));
        data[:] = np.nan;
        
        m = np.std(ro,axis=1);

        for i in range(len(x)):
            data[y.item((i))][x.item((i))] = m.item((i));
            
        return data;

    
    def __getPrefix(self, brdName, brdId):
        if(brdName == ''):
            prefix = '{}{}id{}'.format(FOLDER, DELIM, brdId);
        else:
            prefix = '{}{}{}_id{}'.format(FOLDER, DELIM, brdName, brdId);
        return prefix;
        
    def __plotHeatmap(self, data):
        figure = plt.figure(figsize=(FIG_SIZE_X,FIG_SIZE_Y), dpi=FIG_DPI);       
        ax1 = plt.subplot(111);
        plt.imshow(data, origin="lower");
        plt.xlabel('x');
        plt.ylabel('y');
        plt.colorbar();
        plt.jet();
        (ny,nx) = data.shape;
        ax1.set_xticks(range(0,nx,5));
        ax1.set_yticks(range(0,ny,5));
        ax1.axis('tight');
        return figure;
    
    def __plotRos(self, ros):
        figure = plt.figure(figsize=(FIG_SIZE_X,FIG_SIZE_Y), dpi=FIG_DPI);       
        ax1 = plt.subplot(111);
        (r,readouts) = ros.shape;

        for idx in range(r):
            plt.plot(ros[idx,:]);
            
        ma = np.amax(ros);
        mi = np.amin(ros);
        
        ax1.axis([0,readouts-1,0.9*mi,1.1*ma]);
        plt.xlabel('evaluation');
        plt.ylabel('edge count');

        return figure;
        
        

#VisualizerHeatMap(0);