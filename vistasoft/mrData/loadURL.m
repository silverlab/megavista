function data = loadURL(url)
% data = loadURL(url)
%
% loads data from the mat file specified by the url.   
% This should work just like matlab's built-in function 'load'
% (which should be able to read URL's on it's own!).
%
% RETURNS: a data structure with data from the .mat file specified by 'url'
%
% NOTES: 
%  - Requires that WriteURL.class be in the classpath (ie. in matlab's classpath.txt).
%  - Creates a temporary file in the system's tmp dir.  That drive must
%    have enough free space to buffer the URL contents.
%
% 2001.04.02 Bob Dougherty <bob@white.stanford.edu>
%

tmpFilePath = [tempname,'.mat'];

WriteURL.dumpToFile(url, tmpFilePath);
data = load(tmpFilePath);

delete(tmpFilePath);

return;


% OLD STUFF:

url = java.net.URL(url);

is = url.openStream;
bis = java.io.BufferedInputStream(is);

fs = java.io.FileOutputStream('tmp149235.mat');

% currently, we just read t-series data
data = zeros(646723, 1);
%for(i=1:646723)
for(i=1:64672)    
    h = bis.read; 
    l = bis.read; 
    data(i)=h*256+l; 
end

bis.close;
is.close;