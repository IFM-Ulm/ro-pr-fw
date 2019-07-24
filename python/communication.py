# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 08:51:55 2019

@author: hmandry
"""

import serial
import sys
import glob
from time import sleep

from packet import Packet
import settings as SETTINGS

CMD_NOP = 0x01;

CMD_FILE = 0x02;
CMD_FILE_STORE = 0x01;
CMD_FILE_DELETE = 0xF1;

CMD_BIN = 0x03;
CMD_BIN_INSERT = 0x01;
CMD_BIN_DELETE = 0xF1;
CMD_BIN_DELETE_ALL = 0xF0;

CMD_MEAS = 0x04;
CMD_MEAS_INSERT = 0x01;
CMD_MEAS_DELETE = 0xF1;
CMD_MEAS_DELETE_ALL = 0xF0;
CMD_MEAS_START = 0x02;
CMD_MEAS_START_ALL = 0x03;

ACK = 0x06;
NAK = 0x15;

RESPONSE_ERROR = 0x00;
RESPONSE_SUCCESS = 0x01;
RESPONSE_TIMEOUT = 0x07;
RESPONSE_NAK = NAK;
RESPONSE_TIMEOUT_BYTE = (RESPONSE_TIMEOUT).to_bytes(1, 'big');

TIMEOUT = 50/1000;

def serial_ports():
    """ Lists serial port names
        raises EnvironmentError: On unsupported or unknown platforms
        returns: list of the serial ports available on the system
    """
    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)];
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob('/dev/tty[A-Za-z]*');
    elif sys.platform.startswith('darwin'):
        ports = glob.glob('/dev/tty.*');
    else:
        raise EnvironmentError('Unsupported platform');

    result = [];
    for port in ports:
        try:
            s = serial.Serial(port);
            s.close();
            result.append(port);
        except (OSError, serial.SerialException):
            pass;
    return result;

def printDebug(toPrint):
#    print(toPrint);
    pass;
    
def byteToHexString(byteData):
    result = ""
    for b in range(len(byteData)):
        result += "0x{:02x} ".format(byteData[b]);
    return result;

class Communication(object):
    
    def __init__(self, settings):
        self.__settings = settings;
        self.__connection = serial.Serial();
        
    def connect(self):
        if not self.__connection.isOpen():
            ports = serial_ports();
            if not self.__settings.PORT in ports:
                raise Exception("port " + self.__settings.PORT + " is not available");
            self.__connection = serial.Serial(self.__settings.PORT, self.__settings.BAUDRATE);
            return 1;
        return 0;

    def disconnect(self):
        if self.__connection.isOpen():
            self.__connection.close();
            
    def checkBoard(self):
        if not self.__connection.isOpen():
            return 0;
        sendPacket = Packet(CMD_NOP, CMD_NOP);
        self.__connection.write(sendPacket.getByteStream());
        result = self.__checkResponse(self.__receive_bytes(3), sendPacket);
        return result;
    
    #[success, expected_bytes] = fw_com_setup_meas(com_obj, mode, readouts, time, heatup, partialCounter)
    def setupMeas(self, partialCounter):
	
        expectedBytes = 0;

    	# flush measurements
        sendPacket = Packet(CMD_MEAS, CMD_MEAS_DELETE_ALL);
        self.__connection.write(sendPacket.getByteStream());
        success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
    	
        if not success == RESPONSE_SUCCESS:
            return (success, expectedBytes);
    	   
    	# transmit meas insert
        if self.__settings.MODE == SETTINGS.MODE_PAR:
            expectedBytes = partialCounter * (self.__settings.REPETITIONS + 1) * (4 + 4 * self.__settings.READOUTS * (self.__settings.ROS_PER_BIN + 1));
        else:
            expectedBytes = partialCounter * (self.__settings.REPETITIONS + 1) * (4 + 4 * self.__settings.READOUTS * 2 * self.__settings.ROS_PER_BIN);
        
        payload = (1).to_bytes(2,'little'); #id
        payload += (self.__settings.MODE).to_bytes(1,'little');
        payload += (self.__settings.READOUTS).to_bytes(4,'little');
        payload += (self.__settings.TIME).to_bytes(4,'little');
        payload += (self.__settings.HEATUP).to_bytes(4,'little');
        payload += (self.__settings.COOLDOWN).to_bytes(4,'little');
        payload += (self.__settings.REPETITIONS).to_bytes(4,'little');
                
        sendPacket = Packet(CMD_MEAS, CMD_MEAS_INSERT, payload);
        self.__connection.write(sendPacket.getByteStream());
        
        success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
        
        return (success, expectedBytes);
    
    def startMeas(self):
        sendPacket = Packet(CMD_MEAS, CMD_MEAS_START_ALL);
        self.__connection.write(sendPacket.getByteStream());
        success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
        return success;

    # [success, partialCounter]
    def setupBin(self):
        partialCounter = 0;
        
        # flush bin files
        sendPacket = Packet(CMD_BIN, CMD_BIN_DELETE_ALL);
        self.__connection.write(sendPacket.getByteStream());
        success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
        
        if not success == RESPONSE_SUCCESS:
            return (success, partialCounter);
        
        ## transmit bin infos
        #toplevel 1
        myId = 1;
        isPartial = 0;
        filename = 't1.bin';
        payload = (myId).to_bytes(2,'little');
        payload += (isPartial).to_bytes(1,'little');
        payload += (len(filename)).to_bytes(2,'little');
        payload += str.encode(filename);
        
        sendPacket = Packet(CMD_BIN, CMD_BIN_INSERT, payload);
        self.__connection.write(sendPacket.getByteStream());
        success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
        if not success == RESPONSE_SUCCESS:
            return (success, partialCounter);
        
        # partials of toplevel 1
        isPartial = 1;
        for ind in range(1,self.__settings.NR_BIN_T1+1):
            myId += 1;
            partialCounter += 1;
            filename = 't1i1r{:02d}.bin'.format(ind);
            payload = (myId).to_bytes(2,'little');
            payload += (isPartial).to_bytes(1,'little');
            payload += (len(filename)).to_bytes(2,'little');
            payload += str.encode(filename);
            sendPacket = Packet(CMD_BIN, CMD_BIN_INSERT, payload);
            self.__connection.write(sendPacket.getByteStream());
            success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
            if not success == RESPONSE_SUCCESS:
                return (success, partialCounter);
        
        #toplevel 2
        myId += 1;
        isPartial = 0;
        filename = 't2.bin';
        payload = (myId).to_bytes(2,'little');
        payload += (isPartial).to_bytes(1,'little');
        payload += (len(filename)).to_bytes(2,'little');
        payload += str.encode(filename);
        
        sendPacket = Packet(CMD_BIN, CMD_BIN_INSERT, payload);
        self.__connection.write(sendPacket.getByteStream());
        success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
        if not success == RESPONSE_SUCCESS:
            return (success, partialCounter);
        
        # partials of toplevel 2
        isPartial = 1;
        for ind in range(1,self.__settings.NR_BIN_T2+1):
            myId += 1;
            partialCounter += 1;
            filename = 't2i1r{:02d}.bin'.format(ind);
            payload = (myId).to_bytes(2,'little');
            payload += (isPartial).to_bytes(1,'little');
            payload += (len(filename)).to_bytes(2,'little');
            payload += str.encode(filename);
            sendPacket = Packet(CMD_BIN, CMD_BIN_INSERT, payload);
            self.__connection.write(sendPacket.getByteStream());
            success = self.__checkResponse(self.__receive_bytes(3), sendPacket);
            if not success == RESPONSE_SUCCESS:
                return (success, partialCounter);
            
        return (success, partialCounter);
            
    # waits timeout seconds (default see TIMEOUT) to read expected number of bytes (expectedBytes)
    # if timeout is < 0 it waits until expected bytes are available
    def __receive_bytes(self, expectedBytes, timeout=TIMEOUT):
        
        if(timeout >= 0 and self.__connection.in_waiting < expectedBytes): 
            while(timeout > TIMEOUT):
                sleep(TIMEOUT);
                if self.__connection.in_waiting >= expectedBytes:
                    break;
                timeout -= TIMEOUT;
            else:
                sleep(timeout);
                if self.__connection.in_waiting < expectedBytes:
                    print("TIMEOUT");
                    return RESPONSE_TIMEOUT_BYTE;
        else:#wait endless
            while self.__connection.in_waiting < expectedBytes:
                sleep(TIMEOUT);

        response = self.__connection.read(expectedBytes);
        return response;

    def __checkResponse(self, byteData, packet):
        printDebug("received: " + byteToHexString(byteData))
        if byteData == RESPONSE_TIMEOUT_BYTE:
            return RESPONSE_TIMEOUT;
        elif byteData == packet.getExpectedResponseByteStream():
            return RESPONSE_SUCCESS;
        elif byteData == packet.getNakResponseByteStream():
            return RESPONSE_NAK;
        return RESPONSE_ERROR;
    
    def _getSettings(self):
        return self.__settings;
    
    def _setSettings(self, settings):
        self.__settings = settings;
        
    def isConnected(self):
        return self.__connection.isOpen();

    def readBytes(self, expectedBytes=1, timeout=-1):
        return self.__receive_bytes(expectedBytes, timeout);

    def _debugWrite(self, data):
        self.__connection.write(data);

    def _debugRead(self, expectedBytes=1, timeout=-1):
#        while self.__connection.in_waiting < expectedBytes:
#                sleep(TIMEOUT);
#        response = self.__connection.read(expectedBytes);
#        return response;
        return self.__receive_bytes(expectedBytes, timeout);