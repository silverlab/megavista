function extractPARfile2(stamFile,rootEpi)
%this version write unique PAR files for multiple predictors
%YOU NEED TO CD IN THE STAM DIRECTORY FIRST
% stamfile is the file with the stimuli matrix
% rootEpi is the root from which are epi names generated
if ~exist('stamFile','var');error('Stam file not defined for extractPARfile function'); end
if ~exist('rootEpi','var');disp('Default root epi name used: epi'); rootEpi = 'epi'; end
if ~exist(stamFile,'file');error('Stam file not found for extractPARfile function'); end

disp(['Loading following stam data file: ', stamFile])

    load(stamFile)
    inverted = 0; %if this parameter is 1, it means that LE was not red but green (0 otherwise LE = red)
    if inverted ==1
        answer = input('Data seems inverted (LE sees green), be sure this is correct (1 = yes, 2 = no)');
        if answer>1
           error('Program interrupted') 
        end
    else
        disp('Data are not declared inverted - LE sees red')
    end
    data = runSaved(:,[1,7,10,12,13,15]);
    
                % ----- DATA TABLE STRUCTURE -----
                %    1:  trial # in block; each one is a ON and a OFF
                %    2:  config, where is  closest stimulus 1: left (-/+) - 2: right (+/-)
                %    3: disparity value in arcsec (of left stimulus)
                %    4: correlated (1: yes, 2: anti)
                %    5: block # -chrono order- (one block is either +/- configuration or -/+ configuration and one disp)
                %    6:  runNb
    
    %WRITE one PAR file by EPI, so split data by epi run if more than 1
    runs = logic('union',data(:,6),[]);
    nbRuns = numel(runs);
    if nbRuns>1
        %more than 1 epi
        disp([num2str(nbRuns), ' epis found: split data matrix by epi.'])
        test = data(data(:,6)==runs(1),:); %we assume all runs are equal number of data lines
        dataSplit = nan([size(test),nbRuns]);
        for i=1:nbRuns
            dataSplit(:,:,i) = data(data(:,6)==runs(i),:);
        end
    else
        disp('Only one epi found')
        dataSplit = data;
    end
    
    fixationDuration = 15.7;
        % Event codes
        % 0 Fixation
        % 1 -/+ configuration correlated
        % 2 +/- configuration correlated
        % 3 -/+ configuration anti-correlated
        % 4 +/- configuration anti-correlated
        eventCodes = {'Fixation', '- COR', '+ COR', '- ANT', '+ ANT' }
        colorCodes = [[0.9 0 0]; [0 0.9 0]; [0 0.45 0]; [0 0 0.9]; [0 0 0.45]];
        
    %for each run
    for run = 1:nbRuns
        %select data from that run
        data = dataSplit(:,:,run);
        time = 0; %initialize time
        
        %select one event every 14 (given in each block, all 14 trials are identical)
        data = data(1:14:size(data,1),:);
        currentLine = 1; %initialize line of the design matrix in par file

        %Start run with fixation
        parfile = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};       
        time = time+fixationDuration;
        currentLine = currentLine + 1;

        for i=1:size(data,1) %go through each data line
            
            %Given we split data between runs, the following case should not happen
            %anymore (detection of change of run): so I comment it
            %I keep a little code after, to detect if this is actually
            %occuring because it would mean something went wrong...
%             if i>1 && data(i,6)~=data(i-1,6) %DETECT CHANGE OF RUN (we assume a run covers always more than a single data line)
%                 %finish with fixation
%                     parfile(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
%                     currentLine = currentLine + 1;
%                     time = time+fixationDuration;
%                 %start next run with fixation
%                     parfile(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
%                     currentLine = currentLine + 1;
%                     time = time+fixationDuration;
%             end
            if i>1 && data(i,6)~=data(i-1,6) %DETECT CHANGE OF RUN
                error('We detected a change of run in the epi data: that should not happen - check the code')
            end
            
                
                if inverted ==1 %deal with inverted eyes (this invert the configuration)
                    code = 3-data(i,2);
                else
                    code = data(i,2);
                end
                
                if data(i,4)==1 % correlated
                    codeEvent = code ;
                    codeEvent2 = code + 1;
                else %uncorrelated
                    codeEvent = code + 2;
                    codeEvent2 = code + 3;
                end
                parfile(currentLine,:) = {time codeEvent eventCodes{codeEvent2} colorCodes(codeEvent2,1) colorCodes(codeEvent2,2) colorCodes(codeEvent2,3)};                           

            %move to next event line
            currentLine = currentLine + 1;
            time = round(1000*(time+14*2*0.56075))/1000;
        end

        %finish with fixation on last run
        parfile(currentLine,:)  = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};

        parfile
        writeMatToFile(parfile,[rootEpi,sprintf('%02.f',runs(run)),'.par'])
    end
end

function writeMatToFile(matvar,fileName)
    if exist(fileName,'file')==2; error(['File ',fileName,' exists, first delete to avoid concatenation']); end
    try  
        file = fopen(fileName, 'a');
        str=char(universalStringConverter(matvar,[],2));
        fprintf(file,sprintf('%s', str));    
        fclose(file);
        disp(['Success in writing file ', fileName]);
    catch errors
        disp('extractPARFile error: Writing the file failed')
        fclose(file);
        rethrow(errors)
    end
end