function options = svmInitOptions(varargin)
    % Lib SVM options
    options.svm_type = [];
    options.kernel_type = 0;
    options.degree = [];
    options.gamma = [];
    options.coef0 = [];
    options.cost = [];
    options.nu = [];
    options.epsilon_loss = [];
    options.cachesize = [];
    options.epsilon = [];
    options.shrinking = [];
    options.probability_estimates = [];
    options.weight = [];
    options.quiet = 1;
    
    % MATLAB side options
    options.procedure = 'leaveoneout';
    options.log2cvector = -5:2:15;
    options.log2gvector = 3:-2:-15;
    options.paramSelect = false;
    options.verbose = false;
    options.k = 10;
    
    i = 1;
    while (i <= length(varargin))
        if (isempty(varargin{i})), break; end
        switch (lower(varargin{i}))
            case {'options'} % careful with this one and the next - we assume you know what you're doing with the options struct
                options = varargin{i + 1};
            case {'optionsfile'}
                load(varargin{i + 1});
            case {'procedure'}
                options.procedure = varargin{i + 1};
            case {'k'}
                options.k = varargin{i + 1};
            case {'paramselect'}
                options.paramSelect = 1;
                i = i - 1;
            case {'log2cvector'}
                options.log2cvector = varargin{i + 1};
            case {'log2gvector'}
                options.log2gvector = varargin{i + 1};
            case {'svm_type' 's'}
                options.svm_type = varargin{i + 1};
            case {'kernel_type' 't'}
                options.kernel_type = varargin{i + 1};
            case {'degree' 'd'}
                options.degree = varargin{i + 1};
            case {'gamma' 'g'}
                options.gamma = varargin{i + 1};
            case {'coef0' 'r'}
                options.coef0 = varargin{i + 1};
            case {'cost' 'c'}
                options.coef = varargin{i + 1};
            case {'nu' 'n'}
                options.nu = varargin{i + 1};
            case {'epsilon_loss' 'p'}
                options.epsilon_loss = varargin{i + 1};
            case {'cachesize' 'm'}
                options.cachesize = varargin{i + 1};
            case {'epsilon' 'e'}
                options.epsilon = varargin{i + 1};
            case {'shrinking' 'h'}
                options.shrinking = varargin{i + 1};
            case {'probability_estimates', 'b'}
                options.probability_estimates = varargin{i + 1};
            case {'weight' 'w'}
                options.weight = [varargin{i + 1} varargin{i + 2}];
                i = i + 1;
            case {'quiet' 'q'} % Silence LIBSVM side outputs
                options.quiet = 1;
                i = i - 1;
            case {'verbose'}
                options.verbose = true;
                i = i - 1;
            case {'silent'} % Silence MATLAB side outputs
                options.verbose = false;
                i = i - 1;
            otherwise
                fprintf(1, 'Unrecognized option: ''%s''\n', varargin{i});
                return;
        end
        i = i + 2;
    end
    
end