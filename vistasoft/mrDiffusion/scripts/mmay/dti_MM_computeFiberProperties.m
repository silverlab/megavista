

%% Set Directory Structure and FiberGroup info 
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_adults'};
subs = {'aab050307'};
% subs = {'am0','ao0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
%     'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
%     'sl0','sy0','tk0','tv0','vh0','vr0'};

fiberName = {'rtOC_inf_10_rtLGN_500.mat','ltOC_inf_10_ltLGN_500.mat'};

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
statsFileName = fullfile(baseDir,'MT_Project',['FiberGroupStats_Struct_',date,'.mat']);
textFileName = fullfile(baseDir,'MT_Project',['FiberGroupStats_',dateAndTime,'.txt']);


%% Run the Fiber Properties function and create the stats file.

% Open the stats text file        
[fid message] = fopen(textFileName, 'w');
fprintf(fid, 'Subject Initials \t Fiber Name \t Mean Length \t Min Length \t Max Length\n');

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = fullfile(subDir,'dti06');
            fiberDir = fullfile(dt6Dir,'fibers','conTrack','OT_clean');

            disp(['Processing ' subDir '...']);
            for kk=1:length(fiberName)
                fiberGroup = fullfile(fiberDir, fiberName{kk});
                fg = dtiReadFibers(fiberGroup);
                dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

                % Compute the fiber statistics
                coords = horzcat(fg.fibers{:})';
                numberOfFibers=numel(fg.fibers);
                %fiberLength=NaN(1, 3);

                % Measure the step size of the first fiber. They *should* all be the same!
                stepSize = mean(sqrt(sum(diff(fg.fibers{1},1,2).^2)));
                fiberLength = cellfun('length',fg.fibers);


                %The rest of the computation does not require remembering which node
                %belongd to which fiber.

                [val1,val2,val3,val4,val5,val6] = dtiGetValFromTensors(dt.dt6, coords, inv(dt.xformToAcpc),'dt6','nearest');
                dt6 = [val1,val2,val3,val4,val5,val6];

                % Clean the data in two ways.
                % Some fibers extend a little beyond the brain mask. Remove those points by
                % exploiting the fact that the tensor values out there are exactly zero.
                dt6 = dt6(~all(dt6==0,2),:);

                % There shouldn't be any nans, but let's make sure:
                dt6Nans = any(isnan(dt6),2);
                if(any(dt6Nans))
                    dt6Nans = find(dt6Nans);
                    for ii=1:6
                        dt6(dt6Nans,ii) = 0;
                    end
                    fprintf('\ NOTE: %d fiber points had NaNs. These will be ignored...',length(dt6Nans));
                    disp('Nan points (ac-pc coords):');
                    for ii=1:length(dt6Nans)
                        fprintf('%0.1f, %0.1f, %0.1f\n',coords(dt6Nans(ii),:));
                    end
                end

                % We now have the dt6 data from all of the fibers.  We extract the
                % directions into vec and the eigenvalues into val.  The units of val are
                % um^2/sec or um^2/msec ... somebody answer this here, please.
                [vec,val] = dtiEig(dt6);

                % Tragically, some of the ellipsoid fits are wrong and we get negative eigenvalues.
                % These are annoying. If they are just a little less than 0, then clipping
                % to 0 is not an entirely unreasonable thing. Maybe we should check for the
                % magnitude of the error?
                nonPD = find(any(val<0,2));
                if(~isempty(nonPD))
                    fprintf('\n NOTE: %d fiber points had negative eigenvalues. These will be clipped to 0...\n',numel(nonPD));
                    val(val<0) = 0;
                end

                threeZeroVals=find(sum(val, 2)==0);
                if ~isempty (threeZeroVals)
                    fprintf('\n NOTE: %d of these fiber points had all three negative eigenvalues. These will be excluded from analyses\n', length(threeZeroVals));
                end

                val(threeZeroVals, :)=[];

                % Now we have the eigenvalues just from the relevant fiber positions - but
                % all of them.  So we compute for every single node on the fibers, not just
                % the unique nodes.
                [fa,md,rd,ad] = dtiComputeFA(val);

                %Some voxels have all the three eigenvalues equal to zero (some of them
                %probably because they were originally negative, and were forced to zero).
                %These voxels will produce a NaN FA
                FA(1)=min(fa(~isnan(fa))); FA(2)=mean(fa(~isnan(fa))); FA(3)=max(fa(~isnan(fa))); %isnan is needed  because sometimes if all the three eigenvalues are negative, the FA becomes NaN. These voxels are noisy.
                MD(1)=min(md); MD(2)=mean(md); MD(3)=max(md);
                radialADC(1)=min(rd); radialADC(2)=mean(rd); radialADC(3)=max(rd);
                axialADC(1)=min(ad); axialADC(2)=mean(ad); axialADC(3)=max(ad);
                length(1) = mean(fiberLength)*stepSize; length(2) = min(fiberLength)*stepSize; length(3) = max(fiberLength)*stepSize;

                %sprintf('\nMean length: %.03f mm (Range = [%.04f, %.04f])\n'
                avgFA = FA(2);
                avgMD = MD(2);
                avgRD = radialADC(2);
                avgAD = axialADC(2);
                avgLength = length(1);
                minLength = length(2);
                maxLength = length(3);


                % Write out the struct and the stats file.
                fgs.(subs{ii}) = avgLength;
                fprintf(fid,'%s\t%s\t%.03f\t%.03f\t%.03f\t\n', subs{ii},fg.name,avgLength,minLength,maxLength);
            end

        else disp('No data found.');
        end
    end

end
% save the struct and the stats file.
save(statsFileName,'fgs'); % save the structure to a .mat file
fclose(fid);

disp('Done!');
return









