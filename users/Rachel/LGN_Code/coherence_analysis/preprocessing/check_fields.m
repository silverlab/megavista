%% Checks a structure to make sure it contains the proper fields
%
%   Input:
%
%       structInstance: a structure to check
%
%       requiredFields: a cell array of field names to verify
%
%       messageTemplate: a string error message with a %s to specify param
%           name
%   
%       defaultValues: a cell array of default values to specify if a
%           required field is missing (optional)
%
%   Output:
%
%       structInstance: the structure with the default values set,
%           unchanged if all fields are properly set
%
function structInstance = check_fields(structInstance, requiredFields, messageTemplate, defaultValues)

    hasDefaults = (nargin == 4);
    if hasDefaults && ~(length(requiredFields) == length(defaultValues))
        error('The # of default values has to match the # of required fields!\n');
    end

    for k = 1:length(requiredFields)
        fieldName = requiredFields{k};
        if ~isfield(structInstance, fieldName)            
        	if ~hasDefaults                
                error(messageTemplate, fieldName);
            else
                dval = defaultValues{k};
                %{
                if isnumeric(dval)
                    sval = sprintf('%f', dval);
                else
                    sval = sprintf('%s', dval);
                end
                fprintf('check_fields: setting %s=%s\n', fieldName, sval);
                %}
                structInstance.(fieldName) = dval; 
            end
        end
    end
