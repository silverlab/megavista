function dti_FFA_ventralFibersXls

% This script will load up an Excel worksheet, and create figures to
% summarize fiber tract properties. 
%
% Assumes an excel sheet with a row per fiber group per subject per
% hemisphere per year (e.g., "Subject1 L ILF Y3"), and columns with the
% different fiber tract measures (e.g., mean FA). 
%
% These fibers were hand segmented by Michael for five subjects (AM, DM,
% ES, SS, VR) over four years (Y1, Y2, Y3, Y4), and here we look only at
% the ventral stream fibers (IFOF, ILF, UF). Details about where these
% fibers are stored and how their properties were computed is here:
% http://vpnl.stanford.edu/internal/wiki/index.php/KidFibers
%
% DY 06/23/2008

if ispc
    xlsDir='W:\projects\Kids\dti\davie\reading_longitude';
else
    xlsDir='/biac1/kgs/projects/Kids/dti/davie/reading_longitude/';
end

xlsFile = 'KGS_ventral_fibers.xls'; 
[nums,strings,xls]=xlsread(fullfile(xlsDir,xlsFile));

% We need to know which column number represents which measure
% Just count across in the Excel sheet (e.g., Column B = 2)
col_length=2;
col_md=10;

col_titles=strings(1,:); % contents of first row (column titles)
row_titles=strings(:,1); % contents of first column (row titles)

% We know that there will be four text chunks separated by spaces
% We take feed each text chunk into a new cell.
%
% Row titles is therefore a 5 column cell array
% (1) original text
% (2) Subject, (3) Year, (4) fiber group, (5) hemisphere

for ii=2:length(row_titles)
    spaces=find(isspace(row_titles{ii}));
    if spaces~=3
        error('Too many spaces'); 
    end
    row_titles{ii,2}=row_titles{ii}(1:spaces(1)-1); % subject initials (e.g., ES)
    row_titles{ii,3}=row_titles{ii}(spaces(1)+1:spaces(2)-1); % year (e.g., Y1)
    row_titles{ii,4}=row_titles{ii}(spaces(2)+1:spaces(3)-1); % fg (e.g., UF)
    row_titles{ii,5}=row_titles{ii}(spaces(3)+1:end); % hemisphere (e.g., left)
end

% Convert the cell array row_titles into a struct theRows. Then we
% find all the unique strings for each of the fields (subjects, years,
% fiber groups, hemispheres). 
variables={'o','s','y','fg','h'};
theRows=cell2struct(row_titles,variables,2);
theSubs=uniquestring({theRows.s});
theYears=uniquestring({theRows.y});
theFgs=uniquestring({theRows.fg});
theHemis=uniquestring({theRows.h});

% Create figure summarizing mean lengths of first fg across the years, with
% a separate line for each subject.

theLength.title='Length';
theLength.index=col_length;

theMD.title='Mean MD';
theMD.index=col_md;

makeAllFigures(xls,theLength,theSubs,theYears,theFgs,theRows,theHemis);
makeAllFigures(xls,theMD,theSubs,theYears,theFgs,theRows,theHemis);

return

%%
function makeAllFigures(xls,theMeasure,theSubs,theYears,theFgs,theRows,theHemis)

% Requires the struct: THEMEASURE
% title field: used for labeling the figure
% index field: column index for this measure

plotThis=zeros(length(theSubs),length(theYears));
for h=1:length(theHemis)
    for ii=1:length(theFgs)
        for jj=1:length(theSubs)
            thisSub=find(strcmp({theRows.s},theSubs(jj)));
            thisFg=find(strcmp({theRows.fg},theFgs(ii)));
            thisHemis=find(strcmp({theRows.h},theHemis(h)));
            for yy=1:length(theYears)
                thisYear=find(strcmp({theRows.y},theYears(yy)));
                
                % Get the row number for the particular single fg by
                % finding the index in common between all these sets:
                % theSubs(jj),theFgs(ii),theHemis(h),theYears(yy)
                theIndex=intersect(intersect(intersect(thisSub,thisFg),thisHemis),thisYear);

                % End result in a JJxYY length vector, PLOTTHIS with all the
                % LENGTH (col_length) for the subject across the years         
                plotThis(jj,yy)=xls{theIndex,theMeasure.index};

            end
        end
        
        % Now we have all the info for this particular fiber group, plot it
        makeLineFigForFG(plotThis,theSubs,theFgs{ii},theHemis{h},theMeasure.title);
        
    end
end
return

%%
function makeLineFigForFG(data,lines,fg,h,ytitle)

% Needs three inputs in this order:
% (1) data to plot: matrix with rows = number of lines to plot, 
%     cols = number of x-axis points to plot
% (2) labels for each line
% (3) fiber group label (string)
% (4) hemisphere label (string)
% (5) year label (string)

theColors={'b','g','r','c','m','y','k','b','g','r','c','m','y','k'};

figure

for ii=1:length(lines)
    plot(data(ii,:),theColors{ii})
    hold on
end

title([h ' ' fg]); xlabel('Years'); ylabel(ytitle); legend(lines,'Best');

return



