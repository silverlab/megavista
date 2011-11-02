function pump2XL(indat, sheetname, startPos)
% function pump2XL(indat, sheetname, [startpos])
%
% linking matlab to EXCEL 
%
% Takes a matrix or cell array and places it on a specified row of an excel worksheet
% Data is ordered col to row-wise so a(1:10,1) goes to R1C1:R1C10
% eg. a=rand(64,10);
% pump2XL(a,'Sheet1'); 
% places the matrix in EXCEL at R1C1:R64C10

if(~exist('startPos', 'var'))
    startPos = [1,1];
end

% Find out how big indat is 
inRange=size(indat);
nRows=inRange(1);
nCols=inRange(2);

startRow=startPos(1);
startCol=startPos(2);
endRow=startRow+nRows-1;
endCol=startCol+nCols-1;

% Initialize conversation with Excel.
chan = ddeinit('excel', sheetname);
if (chan~=0)
    % Create the RstartCstart:RendCend string
    range=['R',int2str(startRow),'C',int2str(startCol),':R',int2str(endRow),'C',int2str(endCol)];
    disp(range);
    
    % Poke the data to the Excel spread sheet.
    rc = ddepoke(chan, range, indat);
    
    ddeterm(chan);
else
    disp('Could not open data channel - is Excel running?');
end
