function S = SmoothTsd(V, l)
% Francesco's

l = floor(l / 2) * 2;

hh = hamming(l);

v = Data(V);

t = Range(V, 'ts');

v = conv(v, hh);

v = v(l/2:end-l/2);

v = v / sum(hh);

S = tsd(t, v);
