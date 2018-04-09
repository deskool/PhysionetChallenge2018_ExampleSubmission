# Physionet Challenge 2018: Example Submission in Matlab
This Repository contains an example submission written in Matlab for the 2018 Physionet Challenge, "You Snooze, You Win". Please note that this code is meant for illustrative purposes, entirely. My aim is to help you understand how to: (1) import the challenge dataset, (2) train models using the data and, (3) generate the output files neccesarry to grade your algorithm's performance on the test set.

# What the code does
The code imports the SaO2 for each training subject, and uses the variance of the SaO2 in 60 secnod windows to predict the arousal regions. Importantly, the code trains an ensemble of logistic regression models: one for each subject. When checking the training performance, I look at how well each subject's model re-created the annoataions used to train them. To predict arousals on the held out test data, I use the average prediction across all the models. 

# Pre-requisites to run the example submission script:
1. I assume that you have Matlab 2017a (or higher) installed on your machine. 
2. I assume that you have downloaded the /training and /test data from: https://physionet.org/challenge/2018/.
3. I assume that the example submission files are in the same directory as the /training and /test data folders.



