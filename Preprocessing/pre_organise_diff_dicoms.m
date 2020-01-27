%pre_organise_diff_dicoms
%Author: Virginia Fernandez
%MSc Project. Dataset processing (2019)
%Must be run before organise_diff_dicoms.m

%Arguments:
%File: Sample subject, phase and sequence from which we can extract an info
%sturcture from its DICOM file. 
%Output:
%Info structure, switches, diff_param and prot, necessary to make
%organise_diff_dicoms work. 

function[info, switches,diff_param,prot]= pre_organise_diff_dicoms(file)

%All the following data must be initialized so that it don't give problems
%when running organise_diff_dicoms

switches.spiral=0;
switches.ex_vivo_data=0;
switches.allow_roi_interp=0;
switches.disable_rr_correction=0;
switches.la_data=0;
switches.strain_correction=0;
switches.tensor_calculation_method=1;
switches.negative_eigenvalues_method=1;
switches.HA_wrap_stop=0;
switches.export_VTK=0;
switches.export_DT=0;
switches.static_GUI=0;
switches.save_good_and_bad_dicoms=0;
switches.use_nominal_interval=1;
switches.attempt_tractography=0;
switches.use_ai=0;
switches.automate_with_ai=0;
switches.poor_thr=0;
switches.diff_dir_rot=0;
switches.additional_cropping=0;
switches.export_tortoise_text_file=0;
switches.export_B_matrix_and_masks=0;
switches.varian=0;
switches.nullzeros=0;
switches.seg_1_start_shift=0;
prot.unwanted_slices = [];
diff_param.b_value_exclude =0;
diff_param.b_value_ref =0;
diff_param.RR_interval=[];
diff_param.RR_interval_factor = 0;
diff_param.assumed_RR_interval =0;

cd(file);
%get all the *.IMA files
info.diffusion_files = dir('*.DCM');
info.number_of_files = length(info.diffusion_files);

end