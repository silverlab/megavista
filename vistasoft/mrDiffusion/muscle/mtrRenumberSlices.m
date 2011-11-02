function mtrRenumberSlices(anIfile, skipNum, newStartNum, outFileBase,outFileExt)
% skipNum : 0 (no skip) only beginning

if (ieNotDefined('outFileExt'))
    outFileExt = '';
end
% Get all I files in this directory
allIfileNames = getIfileNames(anIfile);

% Assume the I files are returned in order and renumber from the new start
nImages = length(allIfileNames);
nStart = 1 + skipNum;
count = 1;
for ii = nStart:nImages
    cmd = sprintf('cp %s %s%03i%s',allIfileNames{ii},outFileBase,count+newStartNum-1,outFileExt);
    system(cmd);
    disp(cmd);
    count = count+1;
end

return;