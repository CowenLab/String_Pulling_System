function d = Align_2_matrices_obj_fun(M1,M2,sh1,sh2)
M2b = circshift(M2,[sh1 sh2]);
d = corrcoef(M1(:),M2b(:));
d = d^2;
