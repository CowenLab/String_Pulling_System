function Summarize_epochs(ctsa_spikes,cell_id,x_tsd,y_tsd, print_flag, cell_range)

% This script will go through all the tfiles in a set and print out
% the activity of a cell across all epochs. 
%
% Information:
%   Place field
%   Scatter field
%   ISI
%   Frequency
%
% INPUT: The top directory for the data set
% OUTPUT: NONE

% cowen Mon Jun 14 15:00:55 1999
TRUE    = 1;
FALSE   = ~TRUE;
ncells  = length(ctsa_spikes{1});
nepochs = length(ctsa_spikes);
nplots  = 4; % number of plots for each epoch(ISI, place field...)
nplace_bins = 20;
 
if nargin <= 4
  print_flag = FALSE;
end
if nargin <= 5
  cell_range = 1:ncells;
end
  
fprintf('Generating data for epoch ');
for epoch = 1:nepochs
  fprintf('%i,', epoch);

  % Generate place fields for all cells
  [TC{epoch},Occ{epoch}] = TuningCurves(ctsa_spikes{epoch}, x_tsd{epoch}, nplace_bins, y_tsd{epoch}, nplace_bins);
  % Generate Scatter fields
  %[SF_x{epoch},SF_y{epoch}] = ScatterFields(ctsa_spikes{epoch}, x_tsd{epoch}, y_tsd{epoch});
  % Generate frequencies for each cell
  F{epoch} = Frequency( ctsa_spikes{epoch});
  % Generate ISIs for all cells
  [mISI{epoch}, vISI{epoch}, nSp{epoch}] = ...
      ISIStats(ctsa_spikes{epoch});
end


for cellid = cell_range
  figure
  orient landscape
  
  % Plot out place fields
  for epoch = 1:nepochs
    % Plot ISI
    if ~isempty(Data(ctsa_spikes{epoch}{cellid}))
      subplot(nplots,nepochs,epoch);
      set(gca,'FontSize',5) % Make a smaller font size.
      HistISI(ctsa_spikes{epoch}{cellid});
      title(['E ' num2str(epoch) ' ID ' num2str(cellid) ' Tet ' ...
	    num2str(cell_id(cellid,1)) '.' num2str(cell_id(cellid,2))])
      % Plot Autocorr
      subplot(nplots,nepochs,epoch + nepochs)
      set(gca,'FontSize',5) % Make a smaller font size.
      Autocorrelation(ctsa_spikes{epoch}{cellid});
      title(['Autocorr, Freq ' num2str(F{epoch}(cellid)) 'Hz']);
      % Plot place fields
      subplot(nplots,nepochs,epoch + nepochs*2)
      set(gca,'FontSize',5) % Make a smaller font size.
      f = find(TC{epoch}{cellid} > 0 & Occ{epoch} == 0); TC{epoch}{cellid}(f) = 0;
      imagesc(TC{epoch}{cellid}./(Occ{epoch}+.0001) - 0.1 * ...
	  ~sign(Occ{epoch}));
      colormap(1-.7*gray);
      colorbar
      set(gca,'FontSize',5) % Make a smaller font size.
      %brighten(.8)
      title('Norm Place Field')
      % Bin spikes by time
      subplot(nplots,nepochs,epoch + nepochs*3)
      set(gca,'FontSize',5) % Make a smaller font size.
      histdata = ndhist(Data(ctsa_spikes{epoch}{cellid})',500,...
	  StartTime(ctsa_spikes{epoch}{cellid}), ...
	  EndTime(ctsa_spikes{epoch}{cellid}));
      plot(histdata)
      title('histogram of spikes')
      xlabel([Time_string(StartTime(ctsa_spikes{epoch}{cellid})) ...
	    ' to ' Time_string(EndTime(ctsa_spikes{epoch}{cellid}))])
      ylabel('spikes')
      % Plot Spike by position
      %subplot(nplots,nepochs,epoch + nepochs*3)
      %set(gca,'FontSize',5) % Make a smaller font size.
      % reduce the size of the data
      %r = Range(x_tsd{epoch},'ts');
      %x = Data(x_tsd{epoch});
      %y = Data(y_tsd{epoch});
      %bins = 1000
      %%mins = min(Data(x_tsd{epoch}) + Data(y_tsd{epoch}) );
      %maxs = max(Data(x_tsd{epoch}) + Data(y_tsd{epoch}) );
      %sv = ndhist([Data(SF_x{epoch}{cellid}) + ...
%	    Data(SF_y{epoch}{cellid})]',bins,mins, maxs)
      %sr = ndhist([Data(x_tsd{epoch}) + Data(y_tsd{epoch})]',bins,mins, ...
%	  maxs)
     
     % plot(sv,'.'); hold on; plot(sr,'ro')
      
      %stp = 20;
      %plot(r(1:stp:end),x(1:stp:end)+ y(1:stp:end),'b.','MarkerSize',2)
      %hold on;
      %plot(Range(SF_x{epoch}{cellid},'ts'),Data(SF_x{epoch}{cellid})+Data(SF_y{epoch}{cellid}),'r.','MarkerSize',4);
      %title('Spikes in x+y');
      %xlabel('timestamps');
      % Plot Scatterfield
      %subplot(nplots,nepochs,epoch + nepochs*4)
      %set(gca,'FontSize',5) % Make a smaller font size.
      %plot(x(1:stp:end),y(1:stp:end),'.','MarkerSize',2);
      %hold on
      %plot(Data(SF_x{epoch}{cellid}),Data(SF_y{epoch}{cellid}),'r.','MarkerSize',4);
      %title('Spikes in x+y');
      %xlabel('x postion');
      
    end %if

  end % for epoch

  if print_flag
    disp('printing')
    printopt
    savtoner('save')
    print %-dps test
    %!du -k test*
    close
    %disp('Pausing for 10 min-- lest printer Que get battered');
    %pause(8*60);
    %pause
  end
end

