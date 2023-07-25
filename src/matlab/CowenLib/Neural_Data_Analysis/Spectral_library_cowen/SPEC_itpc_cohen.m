function itpc = SPEC_itpc_cohen(PH)
% Assumes each ROW is a trial, each column is a point in time or space.
% Inter trial phase coherence.
% http://www.mikexcohen.com/lecturelets/itpc/itpc.html
%
% Cowen

itpc = abs(mean(exp(1i*PH)));


