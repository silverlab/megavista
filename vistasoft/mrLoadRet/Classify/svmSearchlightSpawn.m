function command = svmSearchlightSpawn(path, folds, growBy, optionsFile)
    if (notDefined('path')), path = pwd; end
    if (notDefined('folds')), folds = [1 1]; end
    if (notDefined('growBy')), growBy = 3; end
    if (notDefined('optionsFile')), optionsFile = []; end
    
    shellcmd.matlab = 'matlab -nodesktop -nosplash -nojvm -r ';%'/usr/bin/nohup ~knk/kendrick/runmatlabinbg.pl 0 "';%
    shellcmd.fnName = 'svmSearchlight';
    shellcmd.fnArgs = ['''''' path '''''' ',[%d %d %d],' num2str(growBy)];
    if (~isempty(optionsFile))
        shellcmd.fnArgs = [shellcmd.fnArgs ',''optionsfile'',' optionsFile];
    end
    shellcmd.exit = '" output &';%'exit; "';
    shellcmd.fnCall = [ shellcmd.fnName '(' shellcmd.fnArgs ')' ];
    
    command = shellcmd.matlab;
    for i = 1:folds(1)
        command = [command sprintf([shellcmd.fnCall '; '], i, folds(1), folds(2))];
    end
    command = [command shellcmd.exit];
    %unix(command);
end

