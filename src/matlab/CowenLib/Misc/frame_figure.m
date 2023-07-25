function frame_figure()
axis tight
a = axis(gca);
a(1) = a(1)-.05*(a(2) - a(1));
a(2) = a(2)+.05*(a(2) - a(1));
a(4) = a(4)+.05*(a(4) - a(3));
axis(a)