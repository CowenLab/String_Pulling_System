function chnum = getIntanChannelNumber(IF, index)
%Takes specified amplififier channels and spits out which number it
%corresponds to on the drive/channel translation table (1-128).

    chnum = (1 + (IF.amplifier_channels(index).chip_channel)) + (32 * ((IF.amplifier_channels(index).board_stream)));
    %Just remember that the names are still 0-indexed even though the
    %struct isn't.
end
