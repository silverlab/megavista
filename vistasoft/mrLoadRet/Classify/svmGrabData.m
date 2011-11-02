function [data labels] = svmGrabData(svmData, svmLabels, categories, instances)
% [data labels] = svmGrabData(svmData, svmLabels, categories, instances)
%   svmGrabData
%       Given a data set with corresponding labels, retrieve the requested
%       categories and instances within each in the form of a new data and
%       labels matrix.
%
%   e.g. svmGrabData(svmData, svmLabels, [1 3 4], [6 7 8]) will return the
%       6th, 7th, and 8th instance of categories 1, 3, and 4 in svmData, 
%       using svmLabels for reference.
%   
%   param matrix svmData - m x n (instances of categories x features) 
%   param vector svmLabels - m x 1 (categories corresponding to data)
%   param vector<int> categories - 1 x n (categories to retrieve)
%   param vector<int> instances - 1 x n (instances to retrieve)
%   return matrix data - m x n (instances of categories x features)
%   return vector labels - m x 1 (categories corresponding to data)
%
% renobowen@gmail.com [2010]
%

if (size(svmData, 1) ~= size(svmLabels, 1)), error('Data/label vector size mismatch.\n'); end

% Initialize data and labels variables
data    = [];
labels  = [];

% For each of the categories
for i = categories
    % Grab out the data and labels for that category
    tmpData = svmData(svmLabels == i, :);
    tmpLabels = svmLabels(svmLabels == i, :);
    
    % Then concat the relevant instances of that category
    data = [data; tmpData(instances, :)];
    labels = [labels; tmpLabels(instances, :)];
end