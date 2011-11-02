function filePath = mrdGetFileFromDB(id)
% filePath = mrdGetFileFromDB(fileID)
%
% loads data from the file specified by the database ID number.   
%
% RETURNS: path to the local copy of the database file.
%
% NOTES: 
%  - Requires that WriteURL.class be in the classpath (ie. in matlab's classpath.txt).
%  - Creates the file in the system's tmp dir.  That drive must
%    have enough free space to hold the URL contents.
%
% 2001.04.02 Bob Dougherty <bob@white.stanford.edu>
%
url = java.net.URL(['http://sepia.stanford.edu/mrdata/linkFile.php?id=',num2str(id,1)]);

is = url.openStream;
isr = java.io.InputStreamReader(is);
br = java.io.BufferedReader(isr);
s = readLine(br);
s = s.toCharArray';
is.close;

urlTagStart = findstr(s, '<url>');
urlTagEnd = findstr(s, '</url>');
urlTag = s(urlTagStart(1)+5:urlTagEnd(1)-1);

% *** HACK! if the file name is too short, this will fail miserably, 
% especially if we catch a path seperator!
filePath = [tempname,urlTag(max(end-4,1):end)];

WriteURL.dumpToFile(urlTag, filePath);

% we should clean up here- send a note to the server that we're done with this file.

