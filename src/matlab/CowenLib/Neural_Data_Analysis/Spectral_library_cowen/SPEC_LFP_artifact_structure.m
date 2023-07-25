function ART = SPEC_LFP_artifact_structure()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ART = [];
ART.file_name = [];
ART.animal_ID = [];
ART.session = [];
ART.region = [];
ART.thresh_for_noise_mv = [];
ART.auto_start_end_sec = [];
ART.manual_start_end_sec = [];
ART.all_start_end_sec =  [];
ART.bad_dataset = false; % It's so bad we should just not use
ART.filter_params = [];