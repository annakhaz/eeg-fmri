function [status, time0] = startScan_eprime()
% Sample:
% [status, time0] = StartScan_eprime()

status = 0; % unless we have problems

% setup trigger
s = serial('/dev/tty.usbmodem12341','BaudRate', 57600); 

% type 'ls -lh /dev/tty.usbmodem*' in terminal to determine correct port
% name
fopen(s)

% get time0
time0 = GetSecs;

% trigger
fprintf(s,'[t]');
fclose(s);


return;
