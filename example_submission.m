%i Author Mohammad M. Ghassemi, MIT
% -- April 8, 2018 --
% This repository contains an example submission written in Matlab for the 2018 Physionet Challenge: 
% "You Snooze, You Win". Please note that this code is meant for illustrative purposes only. 
% My aim is to help you understand how to: 
% (1) import the challenge dataset, 
% (2) train models using the data and, 
% (3) generate the output files necessary to grade your algorithm's performance on the test set.

% The code imports the SaO2 for each training subject, and uses the variance of the SaO2 in
% 60 second windows to predict the arousal regions. Importantly, the code trains an ensemble 
% of logistic regression models: one for each subject. When checking the training performance,
% I look at how well each subject's model re-created the annotations used to train them. 
% To predict arousals on the held-out test data, I use the average prediction across all the models. 

clear all

%STEP 1: Get information on the subject files
[data_tr, data_te] = get_file_info;

% STEP 2: For each of the training subjects, let's build a model.
for i = 1:length(data_tr)

	display('--------------------------------------------------')
	X_tr = [];
	Y_tr = [];
	display(['Working on Subject ' num2str(i) '/' num2str(length(data_tr))])

	%load all the the data associated with this subject
	signals = load(data_tr(i).signal_location);
	signals = signals.val;

	arousal = load(data_tr(i).arousal_location);
	arousal = arousal.data.arousals;
	
        if length(unique(arousal)) == 1
                display('No arousals detected, skipping subject')
                break;
        end
	
	fs = str2num(data_tr(i).fs);
	n_samples = str2num(data_tr(i).n_samples);
	sid = data_tr(i).subject_id;
	signal_names = data_tr(i).signal_names;

	% find the index of the SaO2 signal.
	sao2_ind = find(contains(signal_names,'SaO2'));

	% select the window we want to use to compute features
	window_size = 60 * fs;
	step = 60 * fs;

	% For each 'window', extract the variance of the SaO2
	ind = 1;
	for j = 1:step:n_samples-step
		X_tr(ind) = var(signals(sao2_ind,j:j+step)); 	
		Y_tr(ind) = max(arousal(j:j+step));
		ind = ind + 1;
	end

	% Set the -1 regions as 1
	toss = find(Y_tr == -1);;
	Y_tr(toss) =1;

	% Fit a logistic regression for each subject and save their model
	display('Training Model...')
	coeff = glmfit(zscore(X_tr),Y_tr','binomial');
	
	% save the model for submission to challenge.
	save([sid '_model'],'coeff');

	% generate the probability vectors
	display('Generating Score...')
	pred_short = glmval(coeff,X_tr,'logit');
	pred= mean(pred_short)*ones(length(arousal),1);
	for j = 1:length(pred_short)
		%if i%1000 == 0
		%display([num2str(100*i/length(pred_short)) '% complete'])
		%end
		paste_in = (j-1)*step+1 : j*step;	
		pred(paste_in) =  pred_short(j)*ones(step,1);
	end	

	%Compute the Area Under Reciever Operator Curve
	valid = find(arousal ~= -1);
        arousals_valid = arousal(valid);
	pred_valid = pred(valid);

	%Evaluate performance on this subject
	[~,~,~,AUC(i)] = perfcurve(arousals_valid,pred_valid,1);
	
	display(['Performance So Far...' num2str(mean(AUC)) ' +/- ' num2str(std(AUC))])

	%Save the performance
	%display(['Saving predictions'])
	%fileID = fopen([sid '.vec'],'w');
	%fprintf(fileID,'%f\n',pred);
	%fclose(fileID);

end

%Collect all the models that were trained
files = dir();
files = {files.name};
models = find(contains(files,'_model'))

%STEP 3: Apply the models to the testing set
for i = 1:length(data_te)

        display('--------------------------------------------------')
        X_te = [];
        display(['Working on Test Subject ' num2str(i) '/' num2str(length(data_te))])

        %load all the the data associated with this subject
        signals = load(data_te(i).signal_location);
        signals = signals.val;

        fs = str2num(data_te(i).fs);
        n_samples = str2num(data_te(i).n_samples);
        sid = data_te(i).subject_id;
        signal_names = data_te(i).signal_names;

        % find the index of the SaO2 signal.
        sao2_ind = find(contains(signal_names,'SaO2'));

        % select the window we want to use to compute features
        window_size = 60 * fs;
        step = 60 * fs;

        % For each 'window', extract the variance of the SaO2
        ind = 1;
        for j = 1:step:n_samples-step
                X_te(ind) = var(signals(sao2_ind,j:j+step));
                ind = ind + 1;
        end

        % load the model for submission to challenge.
        % avg_pred = []
	display('Generating Scores')
	for k = 1:length(models) 
		%loading model
		load(files{models(k)});

        	% generate the probability vectors
        	pred_short = glmval(coeff,X_te,'logit');
        	pred = mean(pred_short)*ones(n_samples,1);
        	for j = 1:length(pred_short)
                	paste_in = (j-1)*step+1 : j*step;
                	pred(paste_in) =  pred_short(j)*ones(step,1);
        	end
	
		%Compute average of the predictions.
		if k > 1
			avg_pred = avg_pred + (pred - avg_pred) / (j+1);
		else
			avg_pred = pred;
		end
	

	end
    	 
        %Save the predictions for submission to the challenge
        display(['Saving predictions'])
        fileID = fopen([sid '.vec'],'w');
        fprintf(fileID,'%.3f\n',avg_pred);
        fclose(fileID);

end


