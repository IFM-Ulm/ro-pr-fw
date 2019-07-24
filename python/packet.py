# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 10:08:08 2019

@author: hmandry
"""

import communication as COMM

class Packet(object):
    
    def __init__(self, command, subcommand, payload = b''):
        self.command = command;
        self.subcommand = subcommand;
        self.payload = payload;
        self.length = 2 + len(self.payload);
        
    def getByteStream(self):
        lengthBytes = (self.length).to_bytes(4, byteorder='little')
        
        p = bytearray();
        for i in range(len(lengthBytes)):
             p.append(lengthBytes[i]);
             
        p.append(self.command);
        p.append(self.subcommand);
        p = p + self.payload;
        return p;
    
    def getExpectedResponseByteStream(self):
        p = bytearray();
        p.append(self.command);
        p.append(self.subcommand);
        p.append(COMM.ACK);
        return p;
    
    def getNakResponseByteStream(self):
        p = bytearray();
        p.append(self.command);
        p.append(self.subcommand);
        p.append(COMM.NAK);
        return p;