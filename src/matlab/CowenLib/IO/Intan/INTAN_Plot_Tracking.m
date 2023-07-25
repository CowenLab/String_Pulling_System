[POS,POSrecids] = INTAN_Extract_POS();
save('POS','POS','POSrecids')

j = jet(6);
POS(POS < 10) = nan;
figure
for ii = 2:7
    plot(POS(:,1),POS(:,ii),'Color',j(ii-1,:));
    hold on
end
title('Position over time - all colors')