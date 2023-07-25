function [h,dims] = Plot_scatterfields(ctsa_spikes,x_pos,y_pos)
skip = 100;
if isa(ctsa_spikes,'ts')
    [SFx, SFy] = ScatterFields({ctsa_spikes}, x_pos,y_pos);
    x = Data(x_pos);
    y = Data(y_pos);
    plot(x(1:skip:end),y(1:skip:end),'c.','MarkerSize',4)
    axis ij
    axis tight
    axis off
    hold on
    plot(Data(SFx),Data(SFy),'k.','MarkerSize',8)
    
 
    axis off
    return
else
    ncells = length(ctsa_spikes);
    h = figure
    cnt = 1;
    dims = [ceil(sqrt( ncells)) ceil(sqrt( ncells))];
    [SFx, SFy] = ScatterFields(ctsa_spikes, x_pos,y_pos);
    x = Data(x_pos);
    y = Data(y_pos);

    for cellid = 1:ncells
        subplot(dims(1),dims(2),cnt) 
        plot(x(1:skip:end),y(1:skip:end),'c.','MarkerSize',4)
        axis ij
        axis tight
        axis off
        hold on
        plot(Data(SFx{cellid}),Data(SFy{cellid}),'k.','MarkerSize',8)
        title([ ' ' num2str(cellid)] )
        cnt = cnt + 1;
    end
end
