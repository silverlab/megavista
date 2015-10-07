function extractPARfile(stamFile,rootEpi)
%YOU NEED TO CD IN THE STAM DIRECTORY FIRST
% stamfile is the file with the stimuli matrix
% rootEpi is the root from which are epi names generated
if ~exist('stamFile','var');error('Stam file not defined for extractPARfile function'); end
if ~exist('rootEpi','var');disp('Default root epi name used: epi_'); rootEpi = 'epi_'; end
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
        % 1 -/+ configuration
        % 2 +/- configuration
        eventCodes = {'Fixation', '-/+ disp', '+/- disp'}
        colorCodes = [[0.9 0 0]; [0 0.9 0]; [0 0 0.9]];
        
    %for each run
    for run = 1:nbRuns
        %select data from that run
        data = dataSplit(:,:,run);
        time = 0; %initialize time
        
        %select one event every 14 (given in each block, all 14 trials are identical)
        data = data(1:14:size(data,1),:);
        currentLine = 1; %initialize line of the design matrix in par file

        %Start run with fixation
        parfileCorrelated = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
        parfileUncorrelated = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};        
        time = time+fixationDuration;
        currentLine = currentLine + 1;

        for i=1:size(data,1) %go through each data line
            if i>1 && data(i,6)~=data(i-1,6) %DETECT CHANGE OF RUN (we assume a run covers always more than a single data line)
                %finish with fixation
                    parfileCorrelated(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
                    parfileUncorrelated(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
                    currentLine = currentLine + 1;
                    time = time+fixationDuration;
                %start next run with fixation
                    parfileCorrelated(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
                    parfileUncorrelated(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
                    currentLine = currentLine + 1;
                    time = time+fixationDuration;
            end
            if data(i,4)==1 % Correlated
                parfileCorrelated(currentLine,:) = {time data(i,2) eventCodes{1+data(i,2)} colorCodes(1+data(i,2),1) colorCodes(1+data(i,2),2) colorCodes(1+data(i,2),3)};
                parfileUncorrelated(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
            else %uncorrelated
                parfileUncorrelated(currentLine,:) = {time data(i,2) eventCodes{1+data(i,2)} colorCodes(1+data(i,2),1) colorCodes(1+data(i,2),2) colorCodes(1+data(i,2),3)};
                parfileCorrelated(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
            end

            %move to next event line
            currentLine = currentLine + 1;
            time = round(1000*(time+14*2*0.56075))/1000;
        end

        %finish with fixation on last run
        parfileCorrelated(currentLine,:)  = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
        parfileUncorrelated(currentLine,:)  = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};

        parfileCorrelated
        parfileUncorrelated
        writeMatToFile(parfileCorrelated,[rootEpi,sprintf('%02.f',run),'_Correlated.par'])
        writeMatToFile(parfileUncorrelated,[rootEpi,sprintf('%02.f',run),'_Uncorrelated.par'])
    end
end

function writeMatToFile(matvar,fileName)
    if exist(fileName,'file')==2; error('File exists, first delete to avoid concatenation'); end
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