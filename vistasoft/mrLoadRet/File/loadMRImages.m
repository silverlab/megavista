function images = loadMRImages(view,imageSize)
%mrSESSION = loadMRImages
%
%Loads the full-size inplane anatomies into the 3-d matrix
%'image'.
%
%Image files are expected to have names 'I.001','I.002',... and 
%should be found in <mrSESSION.homeDir>/Raw/Anatomy/<view.subdir>

%4/10/98  gmb   Wrote it.
%9/21/98  rmk   Added a check to see if working on a pc and adds a 
%               byte-reversing argument to readMRImage if so
%02/22/99  rfd	 Extened byte-reversing check to also cover NT machines.

global HOMEDIR

if(strcmp(computer,'LNX86') | strcmp(computer,'PCWIN'))
  pc=1;
else 
  pc=0;
end

%Get the file name list
dirPathStr = fullfile(HOMEDIR,'Raw','Anatomy',view.subdir);
[nImages,imageNameList] = countFiles('I.*',dirPathStr);

if nImages == 0
  myErrorDlg(['Cannot find any ',view.subdir,' image files!'])
  images = [];
  return
end


%get the file size, if not known
if ~exist('imageSize','var')
  img =  ReadMRImage(fullfile(dirPathStr,imageNameList{1}));
  imageSize = size(img);
  disp(sprintf('%s Images, (%d x %d)',view.subdir,imageSize(1),imageSize(2)));
end

%Now we're ready to load in the images
images = zeros(imageSize(1),imageSize(2),nImages);
for curImage = 1:nImages
  disp(sprintf('Loading %s image %d of %d ...',view.subdir,curImage,nImages));
  if pc
    images(:,:,curImage) = readMRImage(fullfile(dirPathStr,imageNameList{curImage}),0,imageSize,'b');
  else
    images(:,:,curImage) = readMRImage(fullfile(dirPathStr,imageNameList{curImage}),0,imageSize);
  end
end

return

% Debug/test
hiddenIP = initHiddenInplane;
images = loadMRImages(hiddenIP);
showim(images(:,:,1),[0,5e3]);
