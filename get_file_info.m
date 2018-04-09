% Author Mohammad M. Ghassemi, MIT
% -- April 8, 2018 --
% This function imports information about the training and testing
% Set data for the 2018 Physionet Challenge. Specifically, it returns 
% a matlab structures containing:
%     - subject id
%     - signal sampling rate
%     - number of samples
%     - location of the signals file
%     - location of the arousal annoataions (for training set)

%PLEASE NOTE: The script assumes that you have downloaded the data, and is meant
%             to be run from the directory containing the '/training' and '/test'
%             subdirectories

function [data_tr, data_te] = get_file_info()

%STEP 1: Collet the location of the training and testing files.
tr_subdir = dir('training');
te_subdir = dir('test');

%toss directories
tr_subdir(~[tr_subdir.isdir]) = [];
te_subdir(~[te_subdir.isdir]) = [];

%keep only the directory names
tr_subdir = {tr_subdir.name};
te_subdir = {te_subdir.name};

%remove '.' and '..' directories
tr_subdir = tr_subdir(3:end);
te_subdir = te_subdir(3:end);

%STEP 2: Get the files for all the training subjects
for i = 1:length(tr_subdir)
	this_subject = tr_subdir{i};
	this_subject_files = dir(['training/' this_subject]);	
	this_subject_files([this_subject_files.isdir]) = [];
	this_subject_files = {this_subject_files.name};

	%Import the header file
	header_ind = find(contains(this_subject_files,'.hea'));
	fid = fopen(['training/' this_subject '/' this_subject_files{header_ind}],'rt');
	raw_header = textscan(fid,'%s','Delimiter','\n');
	raw_header = raw_header{1};
	fclose(fid);

	%Process the first row of the header file
	header_first_row = strsplit(raw_header{1}, ' ');
	data_tr(i).subject_id = header_first_row{1};  
	data_tr(i).fs = header_first_row{3};
	data_tr(i).n_samples = header_first_row{4};
         
	%Extract the signal names from the remainder of the file.
	for j = 2:length(raw_header)
		header_row = strsplit(raw_header{j}, ' ');
		signal_names{j-1} = header_row{end};
	end	
	data_tr(i).signal_names = signal_names;
	
	%extract the signal location
	mat_file = find(contains(this_subject_files,'.mat')); 
        non_arousal = find( not(contains(this_subject_files,'arousal')));
	signal_ind = intersect(mat_file, non_arousal);
	data_tr(i).signal_location = ['training/' this_subject '/' this_subject_files{signal_ind}];
		

	%extract the arousal locations
	arousal_ind = find(contains(this_subject_files,'-arousal'));
	data_tr(i).arousal_location =['training/' this_subject '/' this_subject_files{arousal_ind}]; 

end

%STEP 3: Get the files for all the testing subjects
for i = 1:length(te_subdir)
        this_subject = te_subdir{i};
        this_subject_files = dir(['test/' this_subject]);
        this_subject_files([this_subject_files.isdir]) = [];
        this_subject_files = {this_subject_files.name};

        %Import the header file
        header_ind = find(contains(this_subject_files,'.hea'));
        fid = fopen(['test/' this_subject '/' this_subject_files{header_ind}],'rt');
        raw_header = textscan(fid,'%s','Delimiter','\n');
        raw_header = raw_header{1};
        fclose(fid);

        %Process the first row of the header file
        header_first_row = strsplit(raw_header{1}, ' ');
        data_te(i).subject_id = header_first_row{1};
        data_te(i).fs = header_first_row{3};
        data_te(i).n_samples = header_first_row{4};

        %Extract the signal names from the remainder of the file.
        for j = 2:length(raw_header)
                header_row = strsplit(raw_header{j}, ' ');
                signal_names{j-1} = header_row{end};
        end
        data_te(i).signal_names = signal_names;

        %extract the signal location
        mat_file = find(contains(this_subject_files,'.mat'));
        non_arousal = find( not(contains(this_subject_files,'arousal')));
        signal_ind = intersect(mat_file, non_arousal);
        data_te(i).signal_location = ['test/' this_subject '/' this_subject_files{signal_ind}];

        %extract the arousal locations
        %arousal_ind = find(contains(this_subject_files,'-arousal'));
        %data_te(i).arousal_location =['test/' this_subject '/' this_subject_files{arousal_ind}];

end




