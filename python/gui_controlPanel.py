# -*- coding: utf-8 -*-
"""
Created on Fri Jun 14 13:00:02 2019

@author: hmandry
"""

from tkinter import Tk, Label, Entry, Button, OptionMenu, StringVar, DISABLED, NORMAL, ttk
from threading import Thread
from time import time
import communication as COMM
import settings as SETTINGS
from binDataHandler import BinDataHandler
from visualizer import VisualizerHeatMap

TITLE = 'chip characterization';

COLOR_WINDOW_BG = 'SystemButtonFace';

LABEL_TEXT_BRD_ID   = 'Board Id';
LABEL_TEXT_BRD_NAME = 'Board Name';
LABEL_TEXT_PORT     = 'COM-Port';
LABEL_TEXT_MODE     = 'readout mode';
LABEL_TEXT_READOUT  = 'readouts';
LABEL_TEXT_HEATUP   = 'heatup';
LABEL_TEXT_COOLDOWN = 'cooldown (clks)';
LABEL_TEXT_TIME     = 'time';

LABEL_WIDTH = 15;
LABEL_ANCHOR = 'e';

ENTRY_WIDTH = 15;
ENTRY_OPTION_WIDTH = ENTRY_WIDTH-6;

STATUS_COLOR_DISCONNECT  = 'crimson';
STATUS_COLOR_CONNECT     = 'limegreen';
STATUS_COLOR_MEASUREMENT = 'cornflowerblue';

ERROR_COLOR_ERROR   = 'red';
ERROR_COLOR_NON     = COLOR_WINDOW_BG;

BUTTON_TEXT_CONNECT     = 'connect';
BUTTON_TEXT_DISCONNECT  = 'disconnect';
BUTTON_TEXT_MEASUREMENT = 'start measurement';
BUTTON_TEXT_VISUALIZE   = 'visualizer';

BUTTON_WIDTH = 20;


TEXT_STATUS_DISCONNECT  = 'disconected';
TEXT_STATUS_CONNECT     = 'conected';
TEXT_STATUS_NO_BOARD    = 'disconected (no board)';
TEXT_STATUS_MEASUREMENT = 'measuring';


DEFAULT_BRD_ID = '01';
DEFAULT_BRD_NAME = '';
DEFAULT_READOUT = '100';
DEFAULT_HEATUP = '0';
DEFAULT_COOLDOWN = '0';

def _doMeasuringThreaded(comm, callback, callbackProgress, callbackError):
            
    TIME = 4;
    PERCENT = 0.25
    callbackProgress("setup binaries");
    (success, parCounter) = comm.setupBin();
    if not success == 1:
        callbackError("setup binaries not successful");
        return;
    else:
        callbackProgress("setup binaries successful")
    (success, expectedBytes) = comm.setupMeas(parCounter);
    if not success == 1:
        callbackError("setup measurement not successful");
        return;
    else:
        callbackProgress("setup measurement successful")
    binData = BinDataHandler(comm._getSettings());
#    binData.setBins(parCounter);
    
    success = comm.startMeas();
    if not success == 1:
        callbackError("start measurement not successful");
        return;
    else:
        callbackProgress("start measurement successful")
    by = binData.getBytesToRead();

    expectedTotal = expectedBytes;
    percentLast = 0;
    
    lastTime = time();

    while expectedBytes >= by:
        data = comm.readBytes(by, timeout=TIME);
        if(time()-lastTime >= TIME):
            callbackError("no Data anymore");
            return;
        else:
            lastTime = time();
        binData.handleData(data);
        expectedBytes -= by;
        percent = (expectedTotal - expectedBytes) / expectedTotal * 100;
        if percent - percentLast >= PERCENT:
            callbackProgress(percent);
            percentLast = percent;
        by = binData.getBytesToRead();
    
    binData.closeFiles();
    
    callback();

class Gui_ControlPanel(object):
    
    
    def __init__(self):
        window = Tk();
        window.title(TITLE);
        window.config(bg=COLOR_WINDOW_BG);
        window.protocol("WM_DELETE_WINDOW", self.__onClose)
        
        labelBrdId      = Label(window, text=LABEL_TEXT_BRD_ID, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        labelBrdName    = Label(window, text=LABEL_TEXT_BRD_NAME, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        labelPort       = Label(window, text=LABEL_TEXT_PORT, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        labelMode       = Label(window, text=LABEL_TEXT_MODE, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        labelReadout    = Label(window, text=LABEL_TEXT_READOUT, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        labelHeatup     = Label(window, text=LABEL_TEXT_HEATUP, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        labelCooldown   = Label(window, text=LABEL_TEXT_COOLDOWN, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        labelTime       = Label(window, text=LABEL_TEXT_TIME, width=LABEL_WIDTH, anchor=LABEL_ANCHOR);
        
        
        variablesPort = StringVar(window);
        ports = COMM.serial_ports();
        variablesPort.set(ports[-1]);
        self.__variablesPort = variablesPort;
        
        variablesMode = StringVar(window);
        modes = list(SETTINGS.MODES);
        variablesMode.set(modes[0]);
        self.__variablesMode = variablesMode;
        
        variablesTime = StringVar(window);
        times = list(SETTINGS.TIMES);
        variablesTime.set(times[0]);
        self.__variablesTime = variablesTime;
        
        entryBrdId      = Entry(window, width=ENTRY_WIDTH);
        entryBrdName    = Entry(window, width=ENTRY_WIDTH);
#        entryPort       = Entry(window, width=ENTRY_WIDTH);
        entryPort       = OptionMenu(window, variablesPort, *ports);
        entryPort.config(width=ENTRY_OPTION_WIDTH);
        entryMode       = OptionMenu(window, variablesMode, *modes);
        entryMode.config(width=ENTRY_OPTION_WIDTH);
        entryReadout    = Entry(window, width=ENTRY_WIDTH);
        entryHeatup     = Entry(window, width=ENTRY_WIDTH);
        entryCooldown   = Entry(window, width=ENTRY_WIDTH);
        entryTime       = OptionMenu(window, variablesTime, *times);
        entryTime.config(width=ENTRY_OPTION_WIDTH);
        
        entryBrdId.insert(0, DEFAULT_BRD_ID);
        entryBrdName.insert(0, DEFAULT_BRD_NAME);
        entryReadout.insert(0, DEFAULT_READOUT);
        entryHeatup.insert(0, DEFAULT_HEATUP);
        entryCooldown.insert(0, DEFAULT_COOLDOWN);
        
        buttonCon           = Button(window, text=BUTTON_TEXT_CONNECT, command=self.__button_action_con, width=BUTTON_WIDTH);
        buttonMeasurement   = Button(window, text=BUTTON_TEXT_MEASUREMENT, command=self.__button_action_measurement, width=BUTTON_WIDTH);
        buttonVisualize     = Button(window, text=BUTTON_TEXT_VISUALIZE, command=self.__button_action_visualize, width=BUTTON_WIDTH);
        labelStatus         = Label(window, text=TEXT_STATUS_DISCONNECT, width=BUTTON_WIDTH, anchor='center', bg=STATUS_COLOR_DISCONNECT);
        labelError          = Label(window, text="", width=BUTTON_WIDTH, anchor='center', bg=ERROR_COLOR_NON);
        
        progress = ttk.Progressbar(window, orient="horizontal", length=300)
        labelProgress       = Label(window, text="", width=ENTRY_WIDTH+BUTTON_WIDTH+LABEL_WIDTH, anchor='center');
        
        labelBrdId.grid(    row=0, column=0);
        labelBrdName.grid(  row=1, column=0);
        labelPort.grid(     row=2, column=0);
        labelMode.grid(     row=3, column=0);
        labelReadout.grid(  row=4, column=0);
        labelHeatup.grid(   row=5, column=0);
        labelCooldown.grid( row=6, column=0);
        labelTime.grid(     row=7, column=0);
        
        entryBrdId.grid(    row=0, column=1, padx=5);
        entryBrdName.grid(  row=1, column=1, padx=5);
        entryPort.grid(     row=2, column=1, padx=5);
        entryMode.grid(     row=3, column=1, padx=5);
        entryReadout.grid(  row=4, column=1, padx=5);
        entryHeatup.grid(   row=5, column=1, padx=5);
        entryCooldown.grid( row=6, column=1, padx=5);
        entryTime.grid(     row=7, column=1, padx=5);
        
        labelStatus.grid(      row=0, column=2, padx=20);
        buttonCon.grid(        row=1, column=2, padx=20);
        buttonMeasurement.grid(row=2, column=2, padx=20);
        buttonVisualize.grid(  row=3, column=2, padx=20);
        labelError.grid(       row=4, column=2, padx=20, rowspan=3);
        
        progress.grid(row=8, column=0, columnspan=3, pady=5);
        labelProgress.grid(row=9, column=0, columnspan=3);
        
        self.__progress = progress;
        self.__labelProgress = labelProgress;
        
        self.__entryBrdId = entryBrdId;
        self.__entryBrdName = entryBrdName;
        self.__entryPort = entryPort;
        self.__entryMode = entryMode;
        self.__entryReadout = entryReadout;
        self.__entryHeatup = entryHeatup;
        self.__entryCooldown = entryCooldown;
        self.__entryTime = entryTime;
        self.__labelStatus = labelStatus;
        self.__labelError = labelError;
        self.__buttonCon = buttonCon;
        self.__buttonMeasurement = buttonMeasurement;
        self.__buttonVisualize = buttonVisualize;
        
        s = SETTINGS.Settings();
        self.__comm = COMM.Communication(s);
        
        self.__measuring = 0;
        
        self.__visWindows = [];
        
        self.__window = window;
        self.__window.mainloop();
        
    def __onClose(self):
        for v in self.__visWindows:
            for w in v.getWindowList():
                try:
                    w.destroy();
                except:
                    pass;
        self.__window.quit();
        self.__window.destroy();

    def __updatePortsOption(self):
        pass
        
    def __button_action_con(self):
        self.__handleConnection();
            
                
#        pass;
        
    def __button_action_measurement(self):
        if self.__measuring == 1:
            self.__measuring = 0;
            self.__buttonMeasurement.config(state=NORMAL);
            self.__buttonCon.config(state=NORMAL);
            self.__progress["value"] = 0;
            self.__labelProgress.config(text = '');
            if self.__comm.isConnected:
                self.__labelStatus.config(bg=STATUS_COLOR_CONNECT, text=TEXT_STATUS_CONNECT);
            else:
                self.__labelStatus.config(bg=STATUS_COLOR_DISCONNECT, text=TEXT_STATUS_DISCONNECT);
        else:            
            entrys = [self.__entryReadout, self.__entryHeatup, self.__entryCooldown];
            val = [0,0,0];
            valid = 1;
            i = 0;
            for e in entrys:
                try:
                    v = int(e.get());
                    e.config(bg='white');
                    if v < 0:
                        e.config(bg='red');
                        valid = 0;
                    else:
                        val[i] = v;
                except ValueError:
                    e.config(bg='red');
                    valid = 0;
                i += 1;
            readouts = val[0];
            heatup = val[1];
            cooldown = val[2];
            
            if valid == 0:
                return;
 
            s = self.__comm._getSettings();
            s.BRD_ID = self.__entryBrdId.get();
            s.BRD_NAME = self.__entryBrdName.get();
            s.MODE = SETTINGS.MODES[self.__variablesMode.get()];
            s.READOUTS = readouts;
            s.HEATUP = heatup;
            s.COOLDOWN = cooldown;
            s.TIME = SETTINGS.TIMES[self.__variablesTime.get()];
            s.updateSettings();
            
            self.__comm._setSettings(s);
            
            if not self.__comm.isConnected():
                self.__handleConnection();
            if not self.__comm.isConnected():#no board found
                return;
            
            self.__measuring = 1;
            self.__labelError.config(text='', bg=ERROR_COLOR_NON);
            self.__buttonMeasurement.config(state=DISABLED);
            self.__buttonCon.config(state=DISABLED);
            self.__labelStatus.config(bg=STATUS_COLOR_MEASUREMENT, text=TEXT_STATUS_MEASUREMENT);
            thread = Thread(target = _doMeasuringThreaded, args = (self.__comm, self.__button_action_measurement, self.__progressBar, self.__errorMeasuring));
            thread.start();
    
    
    def __button_action_visualize(self):
        s = self.__comm._getSettings();
        s.BRD_ID = self.__entryBrdId.get();
        s.BRD_NAME = self.__entryBrdName.get();        
        v = VisualizerHeatMap(s);
        self.__visWindows.append(v);
        pass;
    
    def __progressBar(self, percent):
#        print('{:02.2f} %% geschafft'.format(percent));
        if isinstance(percent,float):
            self.__progress["value"] = percent;
            self.__labelProgress.config(text = '{:02.2f} %'.format(percent));
        else:
            self.__labelProgress.config(text = percent);
        
    def __errorMeasuring(self, message):
        self.__labelError.config(text=message, bg=ERROR_COLOR_ERROR);
        self.__button_action_measurement();

    def __handleConnection(self):
        if self.__comm.isConnected():
            self.__comm.disconnect();
            if not self.__comm.isConnected():
                self.__entryPort.config(state=NORMAL);
                self.__buttonCon.config(text=BUTTON_TEXT_CONNECT);
                self.__labelStatus.config(bg=STATUS_COLOR_DISCONNECT, text=TEXT_STATUS_DISCONNECT);
                self.__updatePortsOption();
        else:
            s = self.__comm._getSettings();
            s.PORT = self.__variablesPort.get();
            self.__comm._setSettings(s);
            self.__comm.connect();
            if self.__comm.isConnected():
                if self.__comm.checkBoard() == 1:
                    self.__buttonCon.config(text=BUTTON_TEXT_DISCONNECT);
                    self.__labelStatus.config(bg=STATUS_COLOR_CONNECT, text=TEXT_STATUS_CONNECT);
                    self.__entryPort.config(state=DISABLED);
                else:
                    self.__comm.disconnect();
                    self.__labelStatus.config(bg=STATUS_COLOR_DISCONNECT, text=TEXT_STATUS_NO_BOARD);

    
#To Test     
Gui_ControlPanel();