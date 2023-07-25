function [r , mean_r, std_r, rA, rB, rC,rBA,rBC,rAC] = Multi_partial_xcorr_timeshift(...
    s1,s2,s3, dt_msec, n_timeshifts, tet_id, show_images, bootstrap, use_x_andor_acorr)
%function [r , mean_r, std_r, rA, rB, rC,rBA,rBC,rAC] = Multi_partial_xcorr_timeshift(...
%    s1,s2,s3, dt_msec, n_timeshifts, tet_id, show_images, bootstrap, use_x_andor_acorr)
% INPUT:
%    A,B,C : arrays of ts objects or time(row) by neuron (col) (Q) matrices for each epoch A = S1, B = M, C = S2.
%    tet_id : a vector that provides the tetrode number for each cell in the A, B , and
%      C matrices. For instance, if the first 3 cells are from tetrode one, and the
%      last 2 from tetrode 4, then tet_id would be [1 1 1 4 4]. 
%    dt_msec = if ts objects passed in, then this is the bin size, if matrices, this is ignored
%    show_images = pass a 1 if you wish to view the r matrices.
%    bootstrap = if not 0 then bootstrap the corrcoef (sampling with replacement).
%    use_x_andor_acorr = 1: use xcorr, 2 use acorr, 3 use both
%
% OUPUT:
%    r where r(1) = r_B,A and r(2) = r_B_C, partialling out r_A
%      the r for each interval (C_sub) in the C matrix. r is the partial
%      correlation coefficient, not the EV, which is r^2. Just square the r
%      to get the EV. (Warning about EV: it will give the illusion of pre-activation
%         because the value is squared-- so negative r values will always look positive)
%
%    mean_r = the mean value of the correlations in the r matrix. It is a 
%             vector of 3 elements: [ A_mean, B_mean, C_mean]
%    std_r = the std of the correlations in the r matrix. It is a 
%             vector of 3 elements: [ A_std, B_std, C_std]
%    rA,rB,rC = the cell by cell correlation matrices.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 9/18/01 added the autocorr (except t0) to the analysis.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    show_images = 0 ; % Useful for displaying the r matrices.
end
if nargin < 7
    bootstrap = 0 ; % Don't use bootstrapping by default.
end

if nargin < 8
    use_x_andor_acorr = 1;    
end
% Use the shuffle time and shuffle cell bootstrap method
if bootstrap == 2
    % Reshuffle the C matrix.
end

switch use_x_andor_acorr
case 1
    % Default
    use_xcorr = 1;
    use_acorr = 0;
case 2
    use_xcorr = 0;
    use_acorr = 1;
case 3 
    use_xcorr = 1;
    use_acorr = 1;
otherwise
    error('Improper switch.')
end

if iscell(s1)
    n_cells = length(s1);
    % Get the spike count on each cell before starting (to save time).
    s = [];
    
    for n = 1:n_cells
        s{1}{n} = s1{n} ;%Data(s1{n});
        s{2}{n} = s2{n} ;
        s{3}{n} = s3{n} ;
    end
    
    % get rid of low firing cells
    counter = 1;
    for epoch = 1:3
        for n = 1:n_cells
            if length(Data(s{epoch}{n})) < 100
                cells_to_kill(counter) = n;
                counter = counter + 1;
            end
        end
    end
    
    for epoch = 1:3
        s{epoch} = Remove_cells(s{epoch}, unique(cells_to_kill));
    end
    tet_id(unique(cells_to_kill)) = [];
    
    n_cells = length(s{1});
    % Only look at different cells and do not look at both crosscorr(A,B) and crosscorr(B,A).
    [cellA cellB] = find_cells(n_cells,tet_id);

    for epoch = 1:3
        count = 1;
        xcorrCUM{epoch} = zeros(length(cellA),2*n_timeshifts+1)*nan;
        acorrCUM{epoch} = zeros(n_cells,n_timeshifts)*nan;
        Q = full(Data(MakeQFromS(s{epoch},dt_msec*10)));
        DisplayProgress(epoch, 4)
        for ii = 1:length(cellA)
            % Calculate the cross correlation
            C = xcorr(Q(:,cellA(ii)),Q(:,cellB(ii)),n_timeshifts,'coeff');
            %[C, B] = CrossCorr(s{epoch}{cellA(ii)},s{epoch}{cellB(ii)},dt_msec,n_timeshifts);
            %plot(B,C)
            % Accumulate the results for each cell pair.
            xcorrCUM{epoch}(count,:) = C';
            count = count + 1;
        end
        if use_acorr
            for ii = 1:n_cells
                % Calculate the auto correlation
                A = xcorr(Q(:,ii),Q(:,ii),n_timeshifts,'coeff');
                % Accumulate the results for each cell pair.
                % It's symetric so only take the stuff on one side of t0.
                acorrCUM{epoch}(ii,:) = A(1:n_timeshifts)';
            end
        end
        
    end
    DisplayProgress close
    
else

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    n_cells = Cols(s1);
    
    [cellA cellB] = find_cells(n_cells,tet_id);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    xcorrCUM{1} = zeros(length(cellA),2*n_timeshifts+1)*nan;
    xcorrCUM{2} = xcorrCUM{1};
    xcorrCUM{3} = xcorrCUM{1};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    acorrCUM{1} = zeros(n_cells,n_timeshifts)*nan;
    acorrCUM{2} = acorrCUM{1};
    acorrCUM{3} = acorrCUM{1};
    s1 = full(s1);
    s2 = full(s2);
    s3 = full(s3);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate the cross correlation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if use_xcorr
        for ii = 1:length(cellA)
            
            C1 = xcorr(s1(:,cellA(ii)),s1(:,cellB(ii)),n_timeshifts,'coeff');
            C2 = xcorr(s2(:,cellA(ii)),s2(:,cellB(ii)),n_timeshifts,'coeff');
            C3 = xcorr(s3(:,cellA(ii)),s3(:,cellB(ii)),n_timeshifts,'coeff');
            % Accumulate the results for each cell pair.
            xcorrCUM{1}(ii,:) = C1';
            xcorrCUM{2}(ii,:) = C2';
            xcorrCUM{3}(ii,:) = C3';
            
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate the auto correlations
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if use_acorr
        for ii = 1:n_cells        
            C1 = xcorr( s1(:,ii), s1(:,ii), n_timeshifts, 'coeff' );
            C2 = xcorr( s2(:,ii), s2(:,ii), n_timeshifts, 'coeff' );
            C3 = xcorr( s3(:,ii), s3(:,ii), n_timeshifts, 'coeff' );
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Accumulate the results for each cell pair.
            % It's symetric so only take the stuff on one side of t0.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            acorrCUM{1}(ii,:) = C1(1:n_timeshifts)';
            acorrCUM{2}(ii,:) = C2(1:n_timeshifts)';
            acorrCUM{3}(ii,:) = C3(1:n_timeshifts)';
        end
    end
    
    
 end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert the results into something a little more convenient.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Acorr and Xcorr have to be treated separately as they have different means. 
% Acorr will typically be higher. To make this work you need to normalize acorr
% and xcorr by the z score and then add them.

cA = [];
cB = [];
cC = [];

if use_acorr
    % Normalize by the standard deviation.
    cA = [ acorrCUM{1}(:)/std(acorrCUM{1}(:)) ];
    cB = [ acorrCUM{2}(:)/std(acorrCUM{2}(:)) ];
    cC = [ acorrCUM{3}(:)/std(acorrCUM{3}(:)) ];
end

if use_xcorr & ~use_acorr
    cA = xcorrCUM{1}(:);
    cB = xcorrCUM{2}(:);
    cC = xcorrCUM{3}(:);
end

if use_xcorr & use_acorr
    cA = [ cA; xcorrCUM{1}(:)/std(xcorrCUM{1}(:)) ];
    cB = [ cB; xcorrCUM{2}(:)/std(xcorrCUM{2}(:)) ];
    cC = [ cC; xcorrCUM{3}(:)/std(xcorrCUM{3}(:)) ];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the correlations of the correlations for each interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_to_boot_by_r = 100;

if bootstrap
    tmp = bootstrp(n_to_boot_by_r,'corrcoef',cA,cB);
    rAB = median(tmp(:,2));
    tmp = bootstrp(n_to_boot_by_r,'corrcoef',cB,cC);
    rBC = median(tmp(:,2));
    tmp = bootstrp(n_to_boot_by_r,'corrcoef',cA,cC);
    rAC = median(tmp(:,2));
else
    rAB = diag(corrcoef(cA,cB),1);
    rBC = diag(corrcoef(cC,cB),1);
    rAC = diag(corrcoef(cA,cC),1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the corrcoef (r) for m,s2|s1 for each interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The partial corrcoef calculation...
% partial correlation coeff (r) of B_C|A, r^2 is the explained variance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
boot_no = 1;
r.rBC_A(boot_no) = (rBC - rAB.*rAC) ./ sqrt((1 - rAB.^2).* (1 - rAC.^2));
r.rAB_C(boot_no) = (rAB - rAC.*rBC) ./ sqrt((1 - rBC.^2).* (1 - rAC.^2));
r.rAC_B(boot_no) = (rAC - rBC.*rAB) ./ sqrt((1 - rAB.^2).* (1 - rBC.^2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If bootstrapping by cell, store the current r value in a vector.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r.rAB(boot_no) = rAB;
r.rBC(boot_no) = rBC;
r.rAC(boot_no) = rAC;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function on_same_tet_idx = find_on_same_tet_idx(tet_id)
%function on_same_tet_idx = find_on_same_tet_idx(tet_id)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find indices in the cell by cell R matrix that indicate where correlations
% between cells from the same tetrode reside so that these correlations can be
% eliminated later.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

st_ends = find(diff([999; tet_id(:) ;999])~=0);

M = zeros(length(tet_id));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the regions in the R matrix with conjuncions of within tetrode
% neurons to inf. Inf is a marker that will be used to get the indices
% of these regions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1:length(st_ends)-1
    M(st_ends(ii):(st_ends(ii+1)-1),st_ends(ii):(st_ends(ii+1)-1)) = inf;
end
on_same_tet_idx = find(isinf(M));

return

function [cellA, cellB] = find_cells(n_cells, tet_id)
% Find the cells that will be compared in the xcorr.
[cellA cellB] = find(triu(ones(n_cells,n_cells))==0); % Must be 0, else you get the diagonal
% Get rid of all within tetrode correlations
idx = find(tet_id(cellA)~=tet_id(cellB));
cellA = cellA(idx);
cellB = cellB(idx);
return