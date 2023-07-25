function O = Oscillation_frequencies()
% Spits out the canonoical oscillation frequency ranges.
% see http://www.buzsakilab.com/content/PDFs/Buzsaki2013NeuronSupp.pdf for
% a nice summary of the different rhythms and their ranges.
%
% Cowen 2016
O.delta = [1 3]; % actually, 2 is the typical cutoff, but sometimes 3. I start at 1 because the amplifiers are AC coupled so not sure about .5 Hz being really possible.
O.theta = [5 11]; % 10 is a somewhat average upper cutoff - Some say 8 Hz - but wait, others consider 12 as the upper cutoff (split the diff and chose 11): http://neuralcircuits.uwm.edu/theta-oscillations/
O.alpha = [9 14]; % alpha rhythms (8—10 Hz in humans, listed a little faster in rats) occur during relaxed wakefulness (Adrian and Yamagiwa, 1935)
O.beta  = [15 30]; % beta [25 37]
O.beta1 = [12 20]; % beta1 https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5088183/
O.beta2 = [20 30]; % beta2 https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5088183/
O.beta3 = [25 37]; % Looking at my rat data... 
O.low_gamma = [35 58]; % exploratory behaviour and perceptual tasks (Soltesz and Deschênes, 1993; Bragin et al., 1995; Csicsvari et al., 1999; Gray et al., 1989),
O.low_gamma_colgin = [31 55]; % From Laura Colgin's work.
O.low_gamma2 = [45 55]; %  See Ven der meer Redish paper where they define low gamma 50 as being 45-55 Hz (vSTR). Also see  Masimore et al. (2005) . This was determined by first JUST looking at peak gamma evoked by ketamine - this was then used to compare between drug groups or time..
O.gamma_50 = [45 55]; % Berke 2009 found this.  Meer MAA van der, Redish AD (2009). Low and High Gamma Oscillations in Rat Ventral Striatum have Distinct Relationships to Behavior, Reward, and Spiking Activity on a Learned Spatial Decision Task. Front Integr Neurosci 3: 9. NOTE: slightly differnet ranges in their 2010 paper.van der Meer et al., 2010
% Arg - then in the 2017 piriform paper they call low gamma 45-65 Hz.
O.gamma_80 = [74 94]; % Berke 2009 found ~this but the upper end is aournd 100 hz. Meer MAA van der, Redish AD (2009). Low and High Gamma Oscillations in Rat Ventral Striatum have Distinct Relationships to Behavior, Reward, and Spiking Activity on a Learned Spatial Decision Task. Front Integr Neurosci 3: 9. NOTE: slightly differnet ranges in their 2010 paper.van der Meer et al., 2010
O.gamma_80_b = [70 98]; % Berke 2009 found ~this but the upper end is aournd 100 hz. Meer MAA van der, Redish AD (2009). Low and High Gamma Oscillations in Rat Ventral Striatum have Distinct Relationships to Behavior, Reward, and Spiking Activity on a Learned Spatial Decision Task. Front Integr Neurosci 3: 9. NOTE: slightly differnet ranges in their 2010 paper.van der Meer et al., 2010
% then again the newer vn der meer 2017 goes 70 to 90 Hz.
O.low_gamma_fenton = [35 55]; % From Laura Colgin's work.
O.med_gamma_fenton = [70 90]; % From Laura Colgin's work.
O.high_gamma_lindsey = [65 120]; % Colgin
O.high_gamma_colgin = [80 120]; % Colgin
O.high_gamma = [70 85]; % CITATION??? in our ripple stuff it goes up to 120. This may be incorrect.
O.fast_gamma = [90 140]; % RATS: Sullivan et al., 2011 CA3
O.HFO = [140 160]; % Constrained to what is observed in rats following ketamine injection.
O.HFO2 = [130 160]; % Constrained to what is observed in rats following ketamine injection.
O.ripple = [120 180]; % The lower bound is extended for aging animals.
O.ripple_young = [140 200]; % The lower bound is extended for aging animals.
O.ripple_classic = [140 180]; % 140–180 Hz; O’Keefe and Nadel, 1978; Buzsa´ ki et al., 1992
O.ultra_HFO = [170 250];
O.fast_ripples = [250 800]; % recorded locally from the epileptogenic regions of the hippocampus and the temporal cortex of epileptic humans and rodents (Bragin et al., 1999b; Urrestarazu et al., 2007; Worrell et al., 2008),

clrs = lines(20);
clr2 = colorcube(5);

O.colors.delta = clrs(1,:);
O.colors.theta = clrs(2,:);
O.colors.alpha = clr2(1,:);
O.colors.beta = clrs(3,:);
O.colors.low_gamma = clrs(4,:);
O.colors.high_gamma = clrs(5,:);
O.colors.fast_gamma = clr2(2,:);
O.colors.HFO = clrs(7,:);
O.colors.ripple = clr2(3,:);
