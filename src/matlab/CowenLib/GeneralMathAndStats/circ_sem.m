function s = circ_sem( v)
IX = ~isnan(v);
v = v(IX);
s = circ_std(v)/sqrt(length(v)-1);