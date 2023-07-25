function [ctsa_spikes, tet_id, cell_no, cells_to_keep] = Remove_unwanted_cells(ctsa_spikes,epochs,tet_id,cell_no,LOWthreshold,HIGHthreshold)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get rid of cells that did not fire at all on either maze period.
% Only get rid of those cells that fall outside the thresholds in
% ALL of these epochs (just screwing up on one epoch is not enough
% to ax the cell.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sleep1 = 1; maze1 = 2; sleep2 = 3; maze2 = 4; sleep3 = 5;
cells_to_ax = [];
cnt = 1;
for ep = epochs
    F = Frequency( ctsa_spikes{ep});
    bad_boys{cnt} = [find(F < LOWthreshold | F > HIGHthreshold)];
    cnt = cnt + 1;
end

% This is not elegant but it works.
switch length(bad_boys)
case 1
    real_bad_boys = bad_boys{1};
case 2
    real_bad_boys = intersect(bad_boys{1},bad_boys{2});
case 3
    a = intersect(bad_boys{1},bad_boys{2});
    real_bad_boys = intersect(a ,bad_boys{3});
case 4 
    a = intersect(bad_boys{1},bad_boys{2});
    b = intersect(bad_boys{3},bad_boys{4});
    real_bad_boys = intersect( a , b );
case 5
    a = intersect( bad_boys{1}, bad_boys{2} );
    b = intersect( bad_boys{3}, bad_boys{4} );
    c = intersect( a , b );
    real_bad_boys = intersect( bad_boys{5}, c );
otherwise
    error('more epochs than expected')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wipe out all interneurons and non-spiking neurons in all epochs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cells_to_ax = unique(real_bad_boys)

for epoch = 1:length(ctsa_spikes)
    if(~isempty(ctsa_spikes{epoch}))
        ctsa_spikes{epoch} = Remove_cells(ctsa_spikes{epoch},cells_to_ax);
    end
end
tet_id(cells_to_ax) = [];
cell_no(cells_to_ax) = [];
cells_to_keep = setdiff(1:length(tet_id),cells_to_ax);