  function p = RandPermFast(n)
  % a  faster alternative to randperm. It's not that much faster - maybe 6%
  % from matlab discussion group realated to FEX
  p = 1:n;
  for k = n:-1:2
      r = 1 + floor(k*rand);
      t = p(r);
      p(r) = p(k);
      p(k) = t;
  end