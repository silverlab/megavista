
function []=ecogCombineZ(elecs,bef_win,aft_win,BN,tag_all,plotType,z_cut,minax,maxax,ncols,textOff)
%
% Function to combine Z score plots, which are stored as normERSP in the
% processedData directory.
%
%   []=ecogCombineZ(elecs,bef_win,aft_win,BN,tag_all,[plotType='interp'],[z_cut=2],[minax=-5],[maxax=5],[ncols=5],[textOff=0])
%
%   elecs are the electrodes you want to plot (within one figure)
%   BN is a cell array of block name strings e.g. {'st06_26','st06_30','st06_37'}
%   bef_win and aft_win is the time you want to take a look at-- these must have been processed already (i.e. you must have a normERSP for that duration
%   tag_all is a cell array of condition names
%   %   plotType is a string specifying the type of plot to make-- can be 'interp', '3D', 'imagesc'
%   z_cut is the Z score threshold that will used for plotting when using interpolated (smooth) plots
%   minax and maxax are the Z score axis limits
%   ncols is the number of columns in the plot.  The number of rows will be as many as needed.
%   textOff if a flag that you can use to create the plots without any axis labels, colorbars, or titles (this can be dangerous)
%
% amr March 2010 adapted Mo's plotting and averaging code
%

fontsize = 20;

if length(elecs)==1
    %     fprintf('Do you want to combine all conditions into 1 plot for electrode %d?',elecs(1))
    %     onePlotFlag = input(          '1=yes, 0=no:   ');
    oneFigureFlag = 1;   % put all plots (of all conditions) into one figure because we only have 1 electrode
    fontsize = 20;
else
    oneFigureFlag = 0;
end

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

% Plotting format
if oneFigureFlag
    if notDefined('ncols')
        if length(tag_all)<6   % number of conditions
            ncols = length(tag_all);
        else
            ncols=5;  % max of 5 columns
        end
    end
    nrows = ceil(length(tag_all)/ncols);
else
    if notDefined('ncols')
        if length(elecs)<6
            ncols = length(elecs);
        else
            ncols=5;  % max of 5 columns
        end
    end
    nrows = ceil(length(elecs)/ncols);
end


elecCounter = 0;
% Defaults for plotting
if notDefined('z_cut'),        z_cut =  2;     end  % Z-score threshold
if notDefined('minax'),        minax = -5;    end   % Z-score axis
if notDefined('maxax'),        maxax = 5;     end
if notDefined('textOff'),      textOff = 0;  end    % figure labels
if notDefined('plotType'),     plotType = 'interp';  end

% Do each electrode separately
for ci=elecs
    elecCounter = elecCounter+1;

    % Within each electrode, do each condition (jj) separately
    for jj=1:length(tag_all)
        tag= tag_all{jj};

        % Each block separately (with this condition and this electrode)
        for ii=1:length(BN)
            block_name= BN{ii};
            parFiles = dir([block_name '/par*.mat']);
            parFile = fullfile(block_name,parFiles(1).name);
            load(parFile);

            fs_comp= par.fs_comp;
            freq= par.freq;
            bef_point= floor(bef_win * fs_comp);
            aft_point= ceil(aft_win * fs_comp);
            Npoints= bef_point + aft_point+1;
            %V=regexp(par.Print,par.block,'split');
            %print_root= par.Print;

            fn= sprintf('%s',par.Results);
            normERSPpath = sprintf('%s/normERSP_%s_%s_%s_%s.mat',fn,par.exptname,tag,windurstr,par.block);
            load(normERSPpath); % load normalized ERSP data
            Z_tmp(:,:,ii)= Zscore(:,:,ci);
        end

        % average the Z scores from all the blocks (separately for each condition, which is jj) %%%%%%%%%%%%%%%%%%%%%%%
        Z(:,:,jj)= sum(Z_tmp,3);
        Z(:,:,jj)= Z(:,:,jj)/length(BN);  % THIS IS THE CRUCIAL STEP of averaging!

        if oneFigureFlag
            figure(ci),gcf;   % for each electrode 1 figure
            h = subplot(nrows,ncols,jj);   % subplot each condition
        else
            figure(jj),gcf;   % for each condition 1 figure
            h = subplot(nrows,ncols,elecCounter);  % subplot each electrode
        end
        % Different types of plots
        if strcmp(plotType,'imagesc')
            % One way of plotting directly
            imagesc(Z(:,:,jj),[minax maxax]); axis xy

        elseif strcmp(plotType,'interp') || strcmp(plotType,'3D')
            % Other ways of plotting with interpolation shading and Z score cutoffs
            x=1:Npoints;
            y=1:length(freq);
            zz = Z(:,:,jj);
            to_plot = double(zz.*(zz>z_cut | zz<-z_cut));  % Z score cutoff
            %figure(figNum+1), subplot(nrows,ncols,elecCounter);
            if strcmp(plotType,'3D')
                h= surf(x,y,to_plot);
                zlim([minax*2 maxax*2])
            else
                h= pcolor(x,y,to_plot);
            end
            set(h,'edgecolor','none');
            caxis([minax maxax]);shading interp;
        end

        % Format the plot

        if aft_win>bef_win
            set(gca,'XTick', linspace(bef_point,Npoints,5))
            set(gca,'XTickLabel',{'0', num2str(aft_win/4), num2str(aft_win/2), num2str(3*aft_win/4) num2str(aft_win)})
%             set(gca,'XTick', linspace(bef_point,Npoints,17))
%             set(gca,'XTickLabel',{'0', [], num2str(aft_win/8), [], num2str(aft_win/4), [], num2str(3*aft_win/8), [] ...
%                 num2str(aft_win/2), [], num2str(5*aft_win/8), [], num2str(3*aft_win/4), [], num2str(7*aft_win/8), [], num2str(aft_win)})
            hold on; plot([bef_point bef_point],[0 bef_point],'k--','LineWidth',2)
        elseif aft_win<bef_win
            set(gca,'XTick', linspace(0,bef_point,5));
            set(gca,'XTickLabel',{num2str(-bef_win), num2str(-3*bef_win/4), num2str(-bef_win/2) num2str(-bef_win/4),'0'})
        else
            set(gca,'XTick', [bef_point/2, bef_point+1 bef_point+aft_point/2]);
            set(gca,'XTickLabel',{num2str(-bef_win/2),'0',num2str(aft_win/2) })
        end
        

        set(gca,'YTick',[5 8 12 18 22 28 33 41])

        % grid on top (shows tick marks)
        set(gca,'layer','top')
        
        if ~textOff

            set(gca,'XColor',[0 0 0])
            set(gca,'YTickLabel',{num2str(4.7),num2str(8),num2str(12),num2str(20),num2str(30),num2str(52),num2str(100),num2str(208)},'FontSize',fontsize)
            set(gca,'FontSize',fontsize)
            
            % Remove characters that make matlab titles look bad
            badChars = strfind(tag,'_');
            condtitle = tag;
            condtitle(badChars) =[];
            
            if ~oneFigureFlag
                title(sprintf('%s chan %.3d',condtitle,ci),'FontSize',fontsize);
                xlabel('Time (sec)','FontSize',fontsize);
                ylabel('Frequency (Hz)','FontSize',fontsize);
                colorbar('EastOutside');

            elseif jj<2  % make colorbar in a separate figure
                title(sprintf('%s',condtitle),'FontSize',fontsize);  % don't need electrode info for each plot
                set(gcf,'Name',sprintf('Electrode %d',ci))
                figure('Name','Colorbar'); gcf;
                caxis([minax maxax]);
                colorbar('EastOutside');
            
            else   % just title it
                title(sprintf('%s',condtitle),'FontSize',fontsize);
            end

        else
            colorbar off
            %axis off
            set(gca,'YTickLabel',[])
            set(gca,'XTickLabel',[])
        end

        
        % To save out the plots
        %fp= sprintf('%s/avgiERP_%s_%.3d.jpg',print_root,tag,ci);
        %print(sprintf('-f%d',jj),'-djpeg',fp);
    end

    % To plot differences between conditions
    activeCond = 1;
    baselineCond = 2;
    diffConditionsFigNum = 100;
    %Zd = ecogCombineZCompareConds(Z,activeCond,baselineCond,nrows,ncols,elecCounter,textOff,bef_point,bef_win,aft_point,aft_win,minax,maxax,diffConditionsFigNum,freq,z_cut,plotType);


    %figure(diffConditionsFigNum),h= pcolor(x,y,Zd);


end
