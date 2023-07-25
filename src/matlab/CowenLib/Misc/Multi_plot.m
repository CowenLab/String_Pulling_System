function Multi_plot(C, F, varargin)

% MultiPlotCellArray(C, F, parameters)
%
% plots each elt of C using f
%
% INPUTS
%     C -- Cell Array
%     F -- Matlab function (string). Default is 'imagesc'.
% PARAMETERS
%     maxPerPage (default 64): how many plot to put on a page
%     cmap : the default colormap
%  axis_str: orientation of the axis('ij' is the defaul)
%  printit : to print or not to print

% cowen Wed Apr  7 10:17:23 1999
% Co-opted from ADR 


% Parameters
printColorbar = 0;
maxPerPage = 64;
cmap = jet;
axis_str = 'ij';
printit = 0;
titles = [];
Extract_varargin;
if nargin == 1
  F = 'imagesc';
end

%---------------------------
% check inputs
if ~isa(C, 'cell'); error('TYPE ERROR: C is not a cell array.'); end
if (exist(F) < 2) | (exist(F) > 6); error('TYPE ERROR: function not found.'); end

nElts = length(C);
nPages = ceil(nElts/maxPerPage);
[nL, ppL] = Subplots(min(maxPerPage, nElts));
orient tall
iC = 1;
for iPage = 1:nPages
  
  if iPage > 1 
    % Make a figure if necessary.
    figure;
    orient tall
  end
  
  if iPage < nPages
    nThisPage = maxPerPage;
  else
    nThisPage = nElts - iC + 1;
  end  
  for iThisPage = 1:nThisPage
    s = subplot(nL, ppL, iThisPage);
    set(s,'FontSize',6);
    feval(F, C{iC});
    
    feval('axis', axis_str)
    if ~isempty(titles)
      title([ titles{iC} ' # ' num2str(iC) ]);
    else
      title(iC);
    end
    if printColorbar
      colorbar;
    end
    drawnow;
    colormap(cmap);
    iC = iC + 1;
  end
  if printit
    print
  end
end
