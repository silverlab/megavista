function outData = rd_appendData(dataFilePattern, inData)


dataFile = dir(dataFilePattern);
if numel(dataFile) ~= 1
    error('Too many or too few matching data files.')
else
    data = load(dataFile.name);
end

fieldNames = fields(data);
nFields = numel(fieldNames);

% initialize outData
if ~exist('inData','var')
    for iField = 1:nFields
        fieldName = fieldNames{iField};
        inData.(fieldName) = [];
    end
end

outData = inData;

% append data to outData
for iField = 1:nFields
    fieldName = fieldNames{iField};
    dimToAppend = numel(size(data.(fieldName)))+1;
    outData.(fieldName) = cat(outData.(fieldName), data.(fieldName), dimToAppend);
end