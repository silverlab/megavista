function outData = rd_appendData(dataFilePattern, inData, appendDims)

% deal with input
if nargin < 3
    appendDims = [];
end
if nargin < 2
    inData = [];
end

% load data
dataFile = dir(dataFilePattern);
if numel(dataFile) ~= 1
    error('Too many or too few matching data files.')
else
    data = load(dataFile.name);
end
fieldNames = fields(data);
nFields = numel(fieldNames);

% initialize outData
if isempty(inData)
    for iField = 1:nFields
        fieldName = fieldNames{iField};
        inData.(fieldName) = [];
    end
end
outData = inData;

% append data to outData
for iField = 1:nFields
    fieldName = fieldNames{iField};
    if isempty(appendDims)
        dimToAppend = numel(size(data.(fieldName)))+1;
    else
        dimToAppend = appendDims(iField);
    end
    outData.(fieldName) = cat(dimToAppend, outData.(fieldName), data.(fieldName));
end