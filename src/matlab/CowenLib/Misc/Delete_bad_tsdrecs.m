function o_tsd =  Clean_bad_tsdrect(a_tsd)
D = Data(a_tsd);
R = Range(a_tsd,'ts');
idx = find(R<R(1));
D(idx)=[];
R(idx)=[];
o_tsd = tsd(R,D);
