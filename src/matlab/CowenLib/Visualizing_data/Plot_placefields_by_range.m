function [h,dims] = Plot_placefields_by_range(TS,POS,RANGES,n_place_bins,smooth_factor)
nPlots = Rows(RANGES);
dims = [ceil(sqrt( nPlots)) floor(sqrt( nPlots))];
if nargin < 4
    smooth_factor = 30;
end
if nargin < 3
    n_place_bins = 400;
end

for iP = 1:nPlots
    % Restrict POS
    POSr = POS(POS(:,1) >= RANGES(iP,1) & POS(:,1) <= RANGES(iP,2),:);
    % Restrict spikes
    TSr = TS(TS >= RANGES(iP,1) & TS(:,1) <= RANGES(iP,2));
    [SFx, SFy] = ScatterFields({TSr/100}, tsd(POSr(:,1)/100,POSr(:,2)), tsd(POSr(:,1)/100,POSr(:,3)));
    
    subplot(dims(1),dims(2),iP)
    PF = conv2(double(TC{1}>0)./(Occ+eps),hanning(smooth_factor)*hanning(smooth_factor)');
    figure(1)
    clf
    imagesc(PF');

    axis xy
    hold on
    plot(Data(SFx{1}),Data(SFy{1}),'ro')

end

    clf
    plot(POS(:,2), POS(:,3));
    hold on
    plot(Data(SFx{1}),Data(SFy{1}),'ro')
    %
    [TC,Occ] = TuningCurves(TS, tsd(POS(:,1)/100,POS(:,2)), xx, tsd(POS(:,1)/100,POS(:,3)), xx);
    %[TC,Occ] = TuningCurves({EVT.E.Trigger_Doors/100}, tsd(POS(:,1)/100,POS(:,2)), xx, tsd(POS(:,1)/100,POS(:,3)), xx);
    %% Smooth
    for ii = 1:length(TC)
        PF{ii} = conv2(double(TC{ii}>0)./(Occ+eps),hanning(vv)*hanning(vv)');
        figure(1)
        clf
        imagesc(PF{ii}');
        title(SP{ii}.tfileName)
        drawnow
        pause
    end

    % Cowen: Plots placefields
    [TC,Occ] = TuningCurves({ctsa_spikes}, x_pos, n_place_bins, y_pos, n_place_bins);
    Occ(find(Occ==0)) = nan;
    NTC = TC./Occ;
    imagesc(NTC');
    axis xy
    axis off
    return
else
    ncells = length(ctsa_spikes);
    h = figure
    cnt = 1;
    dims = [ceil(sqrt( ncells)) ceil(sqrt( ncells))];
    [TC,Occ] = TuningCurves(ctsa_spikes, x_pos, n_place_bins, y_pos, n_place_bins);
    Occ(find(Occ==0)) = nan;
    for cellid = 1:ncells
        subplot(dims(1),dims(2),cnt)
        %Plot_placefields(ctsa_spikes{cellid},x_pos, y_pos, n_place_bins);
        imagesc([TC{cellid}./Occ]');
        axis xy
        axis off
        title([ ' ' num2str(cellid)] )
        cnt = cnt + 1;
    end
end
