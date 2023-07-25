function  [an, s] = get_animal(IN);
% IN is a vector of numbers;
bigidx   = find(IN>999999);
smallidx = find(IN<=999999);
an = IN;
an(bigidx)   = floor(an(bigidx)/1000);
an(smallidx) = floor(an(smallidx)/100);

s = zeros(size(IN));
s(bigidx) = IN(bigidx) - an(bigidx)*1000;
s(smallidx) = IN(smallidx) - an(smallidx)*100;
