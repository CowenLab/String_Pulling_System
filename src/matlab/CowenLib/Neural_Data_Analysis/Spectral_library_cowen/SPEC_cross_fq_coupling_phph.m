function [pac, pacp] = SPEC_cross_fq_coupling_phph(LF_phase,HF_phase,window,overlap,num_iter,method)
% Phase-phase coupling. Is the phase of one oscillation modulated by the
% phase of another. This is a way of potentially identifying harmonics.
%
% See Cohen ch 30. This is a work in progress and honestly, I am not sure
% how this gives you more information than PAC. 
% To really get at phase-phase coupling you should align the phases of the
% low frequency oscillation with the phase of the high frequency
% oscillation. It would seem that to do this, just create a PETH using the
% peak of teh low-frequency oscillation against the phase of the
% high-frequenc oscillation at that point in time. Deviation from chance
% would indicate phse locking - the z measure would get you this..
%
% CONSEQUENTLY: This approach is fundamentally different than the approach
% provided in Cohen ch 30 whihc instead looks at the phase of the POWER of
% the high-frequency oscillation - but what if the power of this
% oscillation stays constant, but is phase-aligned with the low-frequency
% oscillation? Such a situation would never be detected by this approach.
%  
% Cowen. 2016.
%%%%%%%%%%%%%%%%%%
if  length(LF_phase)~=length(HF_phase)
    error('LF_phase and HF_phase must have the same length')
end

% How- find peaks of LF. Create histogram of phase of HF at these peaks.
% Do this for each point in time.
% Compare to values created by shuffling.
% Compute the difference.
% If not shuffling, just compute the circular z value of phase modulation.
% Plot the circuilar histogram.
%