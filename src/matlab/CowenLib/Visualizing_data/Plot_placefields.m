function [h,dims] = Plot_placefields(ctsa_spikes,x_pos,y_pos,n_place_bins)
%function [h,dims] = Plot_placefields(ctsa_spikes,x_pos,y_pos,n_place_bins)
% Cowen: Plots placefields
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isa(ctsa_spikes,'ts')
    [TC,Occ] = TuningCurves({ctsa_spikes}, x_pos, n_place_bins, y_pos, n_place_bins);
    Occ(find(Occ==0)) = nan;
    NTC = TC./Occ;
    imagesc(NTC');
    axis xy
    axis off
    return
else
    ncells = length(ctsa_spikes);
    h = figure;
    cnt = 1;
    dims = [ceil(sqrt( ncells)) ceil(sqrt( ncells))];
    [TC,Occ] = TuningCurves(ctsa_spikes, x_pos, n_place_bins, y_pos, n_place_bins);
    Occ(Occ==0) = nan;
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
