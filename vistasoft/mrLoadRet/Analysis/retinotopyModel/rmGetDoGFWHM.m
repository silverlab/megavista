function [fwhmax, fwhmin, difwhmin, minima, positiveArea, totalArea] = rmGetDoGFWHM(model)
%Determines the value of full-width half max of the positive part of the
%difference of gaussian model, and other measures of negative gaussian

%BMH  10/10 Wrote it, with help from WZ

stepsize=0.01; %Fineness of modelled curve increments. Larger values give faster calculation, smaller values are more accurate.

fwhmax=zeros(size(model.sigma2.major)); %Full-width half-max
minima=zeros(size(model.sigma2.major)); %Width at minumum response (if below zero)
fwhmin=zeros(size(model.sigma2.major)); %Full-width half-min (if below zero)
difwhmin=zeros(size(model.sigma2.major)); %Difference in widths of half-min crossings
positiveArea=zeros(size(model.sigma2.major)); %Area under positive response curve
totalArea=zeros(size(model.sigma2.major)); %Area under total response curve

%This gives the areas of each ring in reconstruction of the gaussian, which
%allows volumes of the 3D gaussian to be calculated
ringAreas=0:stepsize:3*max(model.sigma2.major(:));
ringAreasTmp=(ringAreas+stepsize).^2.*pi;
ringAreas=ringAreas.^2.*pi;
ringAreas=single(ringAreasTmp-ringAreas);

%Pre-make x, for speed
%x = 0:stepsize:3*max(model.sigma2.major(:));
x=single([]);
y=single([]);

for k =1:numel(model.sigma2.major)
    if model.sigma.major(k)>0   
          x = 0:stepsize:3*max([model.sigma2.major(k) model.sigma.major(k)]);
          if model.sigma2.major(k)>0
              y = model.beta(1,k,1).*exp((x.^2)./(-2*(model.sigma.major(k).^2)))+model.beta(1,k,2).*exp((x.^2)./(-2*(model.sigma2.major(k).^2)));
          else
              y = model.beta(1,k,1).*exp((x.^2)./(-2*(model.sigma.major(k).^2)));
          end
          
          isNeg = y < max(y)/2;
          ind = find(isNeg, 1, 'first');      % point where it is fwhm
          pointZero = x(ind);
          if isempty(pointZero)
              pointZero=0;
          end
          fwhmax(k) = pointZero;
          
          [minval, minind]=min(y);
          if minval<0
              minima(k)=x(minind);
              isNeg = y < minval/2;
            
              firstNeg=find(isNeg, 1, 'first');
              
              fwhminind = [firstNeg  find(isNeg, 1, 'last')];
              fwhmin(k)=x(fwhminind(2));
              difwhmin(k)=fwhmin(k)-x(fwhminind(1));
              
              %positiveArea(k)=sum(y(1:firstNeg).*ringAreas(1:firstNeg));  %For volume under curve
              positiveArea(k)=stepsize*sum(y(1:firstNeg)); %For area under curve
              
              if isnan(positiveArea(k)) %For very small positive betas, this area can be NaN, which causes porblems. As this outcome is effectively zero area, set to zero.
                  positiveArea(k)=0;
              end
          else
              %positiveArea(k)=sum(y.*ringAreas(1:length(y))); %For volume under curve
              positiveArea(k)=stepsize*sum(y); %For area under curve
              if isnan(positiveArea(k))
                  positiveArea(k)=0;
              end
          end
          
          %totalArea(k)=sum(y.*ringAreas(1:length(y))); %For volume under curve
          totalArea(k)=stepsize*sum(y); %For area under curve
          if isnan(totalArea(k))
              totalArea(k)=0;
          end              
    end
end

%Double all values to get results for whole gaussian. Calculations only for
%half gaussian
fwhmax=fwhmax.*2;
minima=minima.*2;
fwhmin=fwhmin.*2;
difwhmin=difwhmin.*2;
totalArea=totalArea.*2;
positiveArea=positiveArea.*2;

return

