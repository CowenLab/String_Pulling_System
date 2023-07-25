function [idx, templates] = Template_matching(M,templates_in)
%function [idx, templates] = Template_matching(M,templates_in)
% INPUT
%     if only one input arguement, M is a time by trace matrix 
%       of waveforms to be cut.
%     if two input arguements, Template_matching will go through
%       and use the passed in templates(templates_in) to sort
%       the waveforms in M.
% OUTPUT
%     idx are the indices of the rows in M that were cut out.
%     thresholds is a n X 3 matrix. Each row represents a different
%       template. Col 1 is the x coordinate of the template. Col
%       2 is the min Y value of the template, Col 3 is the max.
%

% cowen 8/8/00
if nargin == 1
  templates_in = [];
end
[sym colr] = Get_symbols;
if nargin == 2
  if size(templates_in,2) ~= 3
    error('The templates matrix is the wrong size. Should have 3 cols.')
  end
  idx = 1:size(M,1);
  %-------------------------------------------------------------
  % Go through each template and find those items (idx) that
  % fall within the bounds of the templates. Return those\]
  % indices to the user.
  %-------------------------------------------------------------
  for ii = 1:size(templates_in,1)
    a    = templates_in(ii,1);
    miny = templates_in(ii,2);
    maxy = templates_in(ii,3);
    prev_idx = idx;
    idx = find(M(:,a) > miny & M(:,a) < maxy);
    idx = intersect(prev_idx, idx);
  end
  templates = templates_in;
  return  
end

%h0 = gca;
%set(h0,'Position',[100 100, 800, 800]);
%set(h0,'Color','c');

xdim = 1:size(M,2);
h1 = line(xdim,M');
title(['Identify upper and lower limits of sections of the trace.'])
xlabel('Click in this region thrice to end template matching session.')
% Buttons
%uicontrol(fig, ...
%  'Units', 'normalized', ...
%  'Position' , [0 0 0.09 0.06], ...
%  'String', 'save', ...
%  'Callback', 'saveas(gcf,[get(gcf,''Name'')],''fig'')');

       
% Add a template (need to input 2 points)
% Remove Previous template (Undo)
% Zoom In        (need to input 2 points)
% Zoom Back
% Done


hold on
idx = 1:size(M,1);
templates = [];
h1 = line(xdim,M');
hold on
counter = 1;
while 1
  %-------------------------------------------------------------
  % Get the template boundaries.
  %-------------------------------------------------------------
  
  disp('Press spacebar to select a template')
  pause
  [x y] = ginput(2);
  miny = min(y);
  maxy = max(y);
  
  a = axis;
  if miny < a(3) 
    break
  end
  a = round(x(1));
  %-------------------------------------------------------------
  % Limit the spikes to be within a constrained range
  %-------------------------------------------------------------
  prev_idx = idx;
  idx = find(M(:,a) > miny & M(:,a) < maxy);
  idx = intersect(prev_idx, idx);

  if ~isempty(idx)
    %line(xdim,M')
    h2 = line(xdim,M(idx,:)');
    set(h2,'Color',colr{counter});
  end
  templates = [templates; a miny maxy];
  
  counter = counter + 1;
end

if isempty(idx)
  disp('No traces found')
end
