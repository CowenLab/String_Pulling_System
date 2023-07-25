function [M2new, sh_row, sh_col] = Align_2_matrices(M1,M2)
% function [M2new,sh_row,sh_col] = Align_2_matrices(M1,M2)
%
% Find the best way to shift in 2d the matrix M2 with respect to M1 (M1 is the
% template).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Cauto = xcorr2(M1,M1);

[~,mid_ix_col] = max(max(Cauto));
[~,mid_ix_row] = max(max(Cauto,[],2));

C = xcorr2(M1,M2);

[~,ix_col] = max(max(C));
[~,ix_row] = max(max(C,[],2));

sh_col = ix_col - mid_ix_col;
sh_row = ix_row - mid_ix_row;

M2new = circshift(M2,[sh_row,sh_col]);
