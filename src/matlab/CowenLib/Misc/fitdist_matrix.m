function M = fitdist_matrix(IN,x,varargin)
% I obviously don't know what I am doing.
for iC = 1:Cols(IN)
    
    pd = fitdist(IN(:,iC),'Kernel','Kernel','epanechnikov');
    M(:,iC) = pdf(pd,x);
end