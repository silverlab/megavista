function dat = getDateAndTime
% fucniton dat = getDateAndTime
% Simple fucntion that formats the date and time for use in file names.
% Example: dat = getDateAndTime;
%          dat > 20-Oct-2010_10h41m42
%
% LMP - 20-Oct-2010
dateAndTime     = datestr(now); 
dateAndTime(12) ='_'; 
dateAndTime(15) ='h';
dateAndTime(18) ='m';
dat = dateAndTime;
return