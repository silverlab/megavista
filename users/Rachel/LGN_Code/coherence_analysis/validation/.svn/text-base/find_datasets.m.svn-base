function datasets = find_datasets(rootdir, stimDir, expr)

    if nargin < 3
        expr = [];
    end
    
    %conspecific: zfsongs, conspecific

    datasets = {};
    dcnt = 1;
    fnames = dir(rootdir);
    for k = 1:length(fnames)
        if ~strcmp('.', fnames(k).name) && ~strcmp('..', fnames(k).name)
            if fnames(k).isdir
                
                subdir = fullfile(rootdir, fnames(k).name);
                srPairs = get_sr_files(subdir, stimDir);
                if isstruct(srPairs)
                   
                   matched = 1;
                   if ~isempty(expr)
                       mstr = regexp(subdir, expr, 'match');
                       matched = ~isempty(mstr);
                   end
                       
                   if matched    
                       %fprintf('Found stim/response files in %s\n', subdir);
                       ds = struct;
                       ds.dirname = subdir;
                       ds.srPairs = srPairs;
                       datasets{dcnt} = ds; 
                       dcnt = dcnt + 1;
                   end
                else
                    ds = find_datasets(subdir, stimDir, expr);
                    for j = 1:length(ds)
                        datasets{dcnt} = ds{j};
                        dcnt = dcnt + 1;
                    end
                end
            end
        end
    end

function srPairs = get_sr_files(dataDir, stimDir)

    srPairs = -1;
    stimLinkFiles = get_filenames(dataDir, 'stim[0-9]*', 1);
    respFiles = get_filenames(dataDir, 'spike[0-9]*', 1);
    
    if iscell(stimLinkFiles) && iscell(respFiles) && (length(stimLinkFiles) == length(respFiles))
       
        srPairs = struct;
        nFiles = length(stimLinkFiles);        
        stimFiles = cell(nFiles, 1);
        for k = 1:nFiles
            
            %read stim file and get path to .wav file
            stimLinkFile = stimLinkFiles{k};
            fid = fopen(stimLinkFile);
            wavFile = strtrim(fgetl(fid));
            fclose(fid);
            
            stimFiles{k} = fullfile(stimDir, wavFile);            
        end
        srPairs.stimFiles = stimFiles;
        srPairs.respFiles = respFiles;
    end
    