%i Author Mohammad M. Ghassemi, MIT
% -- April 10, 2018 --

clear all

%STEP 0: Get information on the subject files
[data_tr, data_te] = get_file_info;

% select the window sie and step size we want to use to compute features
fs = str2num(data_tr(1).fs);
window_size = 300 * fs;
step = 300 * fs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 1: For each of the training subjects, let's build a model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(data_tr)

	display('--------------------------------------------------')
	display(['Working on Subject ' num2str(i) '/' num2str(length(data_tr))])
 	X_tr = []; Y_tr = [];

	%load all the the data associated with this subject
	signals      = load(data_tr(i).signal_location); signals = signals.val;
	arousal      = load(data_tr(i).arousal_location); arousal = arousal.data.arousals;
	fs           = str2num(data_tr(i).fs);
	n_samples    = str2num(data_tr(i).n_samples);
	sid          = data_tr(i).subject_id;
	signal_names = data_tr(i).signal_names;

	% find the index of the SaO2 signal.
	sao2_ind = find(contains(signal_names,'SaO2'));

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
	
	% save the model for submission to challenge.i
	display('Saving Model...')
	save([sid '_model'],'coeff');

end

% collect a list of all the trained models
files = dir(); files = {files.name};
models = find(contains(files,'_model'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 2: Apply the models to the testing set, and check performance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(data_tr)

	display('---------------------------------------------------------------')
        display(['Evaluating Models on Training Subject ' num2str(i) '/' num2str(length(data_tr))])
	X_tr = []; Y_tr =[];	

        %load all the the data associated with this subject
        signals      = load(data_tr(i).signal_location); signals = signals.val;
        arousal      = load(data_tr(i).arousal_location); arousal = arousal.data.arousals;
        fs           = str2num(data_tr(i).fs);
        n_samples    = str2num(data_tr(i).n_samples);
        sid          = data_tr(i).subject_id;
        signal_names = data_tr(i).signal_names;

        % find the index of the SaO2 signal.
        sao2_ind = find(contains(signal_names,'SaO2'));

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

        % generate the probability vectors
        display('Generating Scores')
        for k = 1:length(models)
                %loading model
                load(files{models(k)});

                % generate the probability vectors
                pred_short = glmval(coeff,X_tr,'logit');
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

        %Compute the Area Under Reciever Operator Curve
        valid = find(arousal ~= -1);
        arousals_valid = arousal(valid);
        pred_valid = avg_pred(valid);

	%If there are no arousals, skip this subject...
        if length(unique(arousals_valid)) == 1
                display('No arousals detected, skipping subject')
                continue;
        end

        %Evaluate performance on this subject
        [~,~,~,AUC(i)] = perfcurve(arousals_valid,pred_valid,1);

        display(['AUC So Far...' num2str(mean(AUC)) ' +/- ' num2str(std(AUC))])

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 3: Apply the models to the testing set, and save .vec files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(data_te)

        display('--------------------------------------------------')
        X_te = [];
        display(['Scoring Test Subject ' num2str(i) '/' num2str(length(data_te))])

        %load all the the data associated with this subject
        signals = load(data_te(i).signal_location);
        signals = signals.val;

        fs = str2num(data_te(i).fs);
        n_samples = str2num(data_te(i).n_samples);
        sid = data_te(i).subject_id;
        signal_names = data_te(i).signal_names;

        % find the index of the SaO2 signal.
        sao2_ind = find(contains(signal_names,'SaO2'));

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
        fprintf(fileID,'%f\n',avg_pred);
        fclose(fileID);

end


