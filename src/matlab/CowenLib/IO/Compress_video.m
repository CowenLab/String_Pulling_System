function Compress_video(infile, outfile)
% Compress video. 
% Cowen 2019
reader = VideoReader(infile);
writer = VideoWriter(outfile,'Motion JPEG AVI');
writer.FrameRate = reader.FrameRate;
% writer.CompressionRatio = 10;
% writer.FileFormat = 'mp4';
% writer.LosslessCompression = false;
writer.Quality = 75;
% writer.VideoCompressionMethod;
open(writer);
while hasFrame(reader)
   img = readFrame(reader);
   writeVideo(writer,img);
end

close(writer);