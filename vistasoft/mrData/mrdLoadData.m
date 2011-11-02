

url = java.net.URL('http://sepia.stanford.edu/mrdata/linkFile.php?id=2');

is = url.openStream;
isr = java.io.InputStreamReader(is);
br = java.io.BufferedReader(isr);
s = readLine(br);
s = s.toCharArray';
is.close;

urlTagStart = findstr(s, '<url>');
urlTagEnd = findstr(s, '</url>');
urlTag = s(urlTagStart(1)+5:urlTagEnd(1)-1);

d = loadURL(urlTag);