function output=dateTime
 
%========================================
%Goal is to create a 'date and time' string
%easy to access in french style
%========================================
%Created by Adrien Chopin in feb 2008
%
%========================================

    currentTime = clock;
    ye = currentTime(1); mo = currentTime(2); da = currentTime(3);
    ho = currentTime(4); mi = currentTime(5); se = currentTime(6);
    output=sprintf('Date and Time:\t%2d/%2d/%4d\t%2d:%2d:%2.0f', da, mo, ye, ho, mi, se);
end