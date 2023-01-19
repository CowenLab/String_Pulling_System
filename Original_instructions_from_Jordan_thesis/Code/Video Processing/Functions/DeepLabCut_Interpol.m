function [T] = DeepLabCut_Interpol (T)
% interpolates to fill in short ranges of missing values, uses spline
% interpolation for bulk of values and liner interpolation at edges of
% values to avoid erroneous end predictions


M=table2array(T);
MissingThresh=30;%used to be 35 wow
t_uS=M(:,8);
linearLimit=2;

for i=2:2:7
    

    ptloc=~isnan(M(:,i));

    ptchg=diff(ptloc);
    
    ptst=find(ptchg==1)+1;
    pted=find(ptchg==-1);
    
    if pted(1)<ptst(1);
        ptst=vertcat(1,ptst);
    end
    
    if length(ptst)>length(pted)
        
        pted=[pted;length(M(:,i))];
    elseif length(pted)>length(ptst)
        pted=pted(1:end-1);
    end
    
    ptrng=pted-ptst;
    
    for j=1:length(ptrng)
       
        if (ptrng(j)<=4)
            M(ptst(j):pted(j),i)=nan;
            M(ptst(j):pted(j),i+1)=nan;
        end
    end
    
    nanloc=isnan(M(:,i));
    valsToSpline=nanloc;
    valsToLine=logical(zeros(length(valsToSpline),1));
    nanchg=diff(nanloc);
    
    
    
    nanst=find(nanchg==1)+1;
    naned=find(nanchg==-1);
    
    if naned(1)<nanst(1);
        nanst=vertcat(1,nanst);
    end
    
    if length(nanst)>length(naned)
       
        naned=[naned;length(valsToSpline)];
    elseif length(naned)>length(nanst)
        naned=naned(1:end-1);
    end
    
    
    
    
    for j=1:length(nanst)
        
        
        if ((height(T)-nanst(j))<linearLimit)
        %if end of table
            valsToLine(nanst(j):naned(j))=true;

        elseif ((naned(j)-nanst(j))>(linearLimit*2))
        %else if long enough to pad ends with linear ranges
            
            valsToLine(nanst(j):(nanst(j)+linearLimit))=true;
            %valsToSpline(nanst(j):(nanst(j)+30))=false;
            
            valsToLine(naned(j)-linearLimit:naned(j))=true;
            %%valsToSpline(naned(j)-30:naned(j))=false;
        elseif ((naned(j)-nanst(j))<=(linearLimit*2))
            %%            valsToSpline(nanst(j):naned(j))=false;
            valsToLine(nanst(j):naned(j))=true;
        end
        
%         if isnan(M(nanst(j)-1,i))
%             valsToLine(nanst(j):nanst(j)+15)=false;
%         end
    end
    
    rngs=naned-nanst;    
    elimst=nanst((rngs>MissingThresh) );
    elimed=naned((rngs>MissingThresh) );
    
    
    
    for j=1:length(elimst)
        valsToSpline(elimst(j):elimed(j))=false;
        valsToLine(elimst(j):elimed(j))=false;
    end
    
    
    
   
    
    M(valsToSpline,i)=interp1(t_uS(~valsToSpline),M(~valsToSpline,i),t_uS(valsToSpline),'pchip',NaN);
    M(valsToSpline,i+1)=interp1(t_uS(~valsToSpline),M(~valsToSpline,i+1),t_uS(valsToSpline),'pchip',NaN);
    
    M(valsToLine,i)=interp1(t_uS(~valsToLine),M(~valsToLine,i),t_uS(valsToLine));
    M(valsToLine,i+1)=interp1(t_uS(~valsToLine),M(~valsToLine,i+1),t_uS(valsToLine));
    
    
    clear valsToLine valsToSpline
end




T=array2table(M);
end