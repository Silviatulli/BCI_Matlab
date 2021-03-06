close all; clear; clc;

acq = load('Simone240516eoec.mat');

chans = 1:size(acq.data, 2);


% Get dataset and sampling rate
data = acq.data(:,chans)';  % transpose data
fs = 1000; %  sampling rate (Hz)

% Free memory space (important for too large data matrix)
acq.data = [];

nChans = size(data, 1);
 
ax = zeros(1, nChans);
for n = 1:nChans
    ax(n)=subplot(nChans,1,n);
    plot((0:size(data,2)-1)/fs, data(n,:));
    title(sprintf('Channel %d', n));
end

TimeTemp = (0:size(data,2)-1)/fs;
figure
plot(TimeTemp,data(2,:));
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');

TimeTemp = (0:size(data,2)-1)/fs;
figure
plot(TimeTemp,data(3,:));

%Save in an array the EEG signal
row_EEG = data(2,:);
Y = abs(row_EEG);
figure
plot((0:size(data,2)-1)/fs,Y.^2);%Plot the absolute value of the EEG Signal ^2
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');

figure(1000)
plot((0:size(data,2)-1)/fs,Y);%Plot the absolute value of the EEG Signal
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');

%Calculate the mean value of the two conditions (Eyes open and closed)
EyeOpen_M = mean(Y(60000:80000));
EyeOpen_S = std(Y(60000:80000));
EyeClosed_M = mean(Y(20000:40000));
EyeClosed_S = std(Y(20000:40000));

%FIND THE TRIGGERS
TriggerPosition = data(3,:);
TriggerMinValue = 2;%Valore che assume quando premo bottone
nSamples = size(TriggerPosition,2);
indexTrigger = zeros(1,nSamples);
indTemp = 1;

lastTrigger = -1;
boolIndexFound = 1;

for i = 1:nSamples
    if TriggerPosition(i) > TriggerMinValue    
        if(i == lastTrigger+1)
            boolIndexFound = 0;
            lastTrigger = lastTrigger + 1;
        else
            boolIndexFound = 1;
            lastTrigger = -1;
        end
        
        if boolIndexFound == 1
            indexTrigger(indTemp) = i;
            indTemp = indTemp + 1;
            lastTrigger = i;
        end
        
    end
end

numTriggers = indTemp - 1;
TriggersIndexes = indexTrigger(1:numTriggers);%Contains all the index position of the trigger


%CALCULATE THE MEAN FOR N SECONDS
secondsToAnalyze = 2;%Insert number of seconds to consider -----> CAMBIAMIIIIIIIIIIIIIIIIIIIII!

index_start = 1;
index_end = secondsToAnalyze*fs;

roundSeconds = nSamples - mod(nSamples,secondsToAnalyze*fs);

MeanSample = zeros(1,roundSeconds/(secondsToAnalyze*fs));


for i = 1:length(MeanSample)
    MeanSample(i) = mean(Y(index_start:index_end));
    index_start = index_start + (secondsToAnalyze*fs);
    index_end = index_end + (secondsToAnalyze*fs);
end

tempIntervals = roundSeconds/(secondsToAnalyze*fs);
integerRoundSeconds = (roundSeconds/fs) - secondsToAnalyze;
Time = 0:secondsToAnalyze:integerRoundSeconds;

%PLOT THE DATA --> MEANS AND TIME
figure(123)
plot(Time,MeanSample);
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');

figure(1234)
scatter(Time,MeanSample);
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');

%Boolean arrays with eyesclosed(0) and eyesopen(1)
TrInd_New = zeros(1,length(TriggersIndexes));

for i = 1:length(TriggersIndexes)
    TrInd_New(i) = TriggersIndexes(i)/(secondsToAnalyze*fs);
end

TrInd_New = round(TrInd_New);

if mod(length(TrInd_New),2)==0
    AssignTrigger = length(TrInd_New)/2;
else
    AssignTrigger = (length(TrInd_New)+1)/2;
end

BoolTrigger = zeros(1,length(MeanSample));

TriggerStart = -1;
TriggerEnd = -1;

for i = 1:2:AssignTrigger
    TriggerStart = TrInd_New(i);
    TriggerEnd = TrInd_New(i+1);
    
    BoolTrigger(TriggerStart:TriggerEnd)=1;
    
end

figure(2001)
gscatter(Time,MeanSample,BoolTrigger,'br','xo');
hline(10,'g','Boundary');


%Create vector for gscatter --> 1st classifier
Boolean_MeanSample= zeros(1,length(MeanSample));

for i = 1:length(MeanSample)
    if(MeanSample(i)<10)
        Boolean_MeanSample(i) = 1; 
    else
        Boolean_MeanSample(i) = 0;
    end
end

figure(3001)
gscatter(Time,MeanSample,Boolean_MeanSample,'br','xo');
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');
hline(10,'g','Boundary');

%K nearest neighbour --> 2nd classifier
K = 5; %neighbours to consider
BooleanNeighbour = zeros(1,length(MeanSample));
EyesCO = -1;

for i = 1:length(Boolean_MeanSample)
    if i <= K
        BooleanNeighbour(i)= Boolean_MeanSample(i);
    elseif (i+4) >= (length(Boolean_MeanSample))
        EyesCO = sum(Boolean_MeanSample((i-K):(i-1)));
        if EyesCO <= K/2
            BooleanNeighbour(i) = 0;
        else
            BooleanNeighbour(i) = 1;
        end
    else
        EyesCO_Before = sum(Boolean_MeanSample((i-K):(i-1)));
        EyesCO_After = sum(Boolean_MeanSample((i+1):(i+K)));
        
        EyesCO = EyesCO_Before + EyesCO_After;
        
        if EyesCO <= K
            BooleanNeighbour(i) = 0;
        else
            BooleanNeighbour(i) = 1;
        end
    end
end

figure(4001)
gscatter(Time,MeanSample,BooleanNeighbour,'br','xo');
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');

%K nearest neighbour 2
K = 3; %neighbours to consider
K1 = K + 1;
BooleanNeighbour = zeros(1,length(MeanSample));
EyesCO = -1;

for i = 1:length(Boolean_MeanSample)
    if i < K1
        BooleanNeighbour(i)= Boolean_MeanSample(i);
    elseif (i+K) > (length(Boolean_MeanSample))
        EyesCO = sum(Boolean_MeanSample((i-K):(i)));
        if EyesCO <= K1/2
            BooleanNeighbour(i) = 0;
        else
            BooleanNeighbour(i) = 1;
        end
    else
        EyesCO = sum(Boolean_MeanSample((i-K):(i+K)));
        
        if EyesCO <= K1
            BooleanNeighbour(i) = 0;
        else
            BooleanNeighbour(i) = 1;
        end
    end
end

figure(4002000)
gscatter(Time,MeanSample,BooleanNeighbour,'br','xo');
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');


%REAL TIME SIMULATION

TimeInterval_Sec = 1;%Valore da cambiare per cambiare intervallo
AnalysisFrequency = 1000;%Valore in millisecondi per effettuare l'analisi dei dati

SamplesToAnalyze = TimeInterval_Sec * fs;
Temp_Start = 1;
Temp_End = AnalysisFrequency;

StopAnalysis = (nSamples-(mod(nSamples,AnalysisFrequency)))/AnalysisFrequency;

StreamingMean = zeros(1,StopAnalysis);

for i = 1:StopAnalysis
    if Temp_End - SamplesToAnalyze <= 0
        StreamingMean(i) = mean(Y(1:Temp_End));     
    else
        StreamingMean(i) = mean(Y((Temp_End-SamplesToAnalyze):Temp_End));
    end
    
    Temp_End = Temp_End + AnalysisFrequency;
end

Time = 0:(AnalysisFrequency/fs):((nSamples-(mod(nSamples,AnalysisFrequency)))/fs);
Time = Time(1:(length(Time)-1));

figure(5001)
scatter(Time,StreamingMean);
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');
%hline(10,'g','Boundary');

%figure(5002)
%scatter(Time(1:10),StreamingMean(1:10));

%Save StreamingMean in .dat
csvwrite('csvlist.dat',StreamingMean)
type csvlist.dat


%Create vector for gscatter
Boolean_Streaming = zeros(1,length(StreamingMean));

for i = 1:length(StreamingMean)
    if(StreamingMean(i)<10)
        Boolean_Streaming(i) = 1; 
    else
        Boolean_Streaming(i) = 0;
    end
end

%figure
%gscatter(Time(1:10),StreamingMean(1:10),Boolean_Streaming(1:10),'br','xo')
%;

figure(6001)
gscatter(Time,StreamingMean,Boolean_Streaming,'br','xo');
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');
hline(10,'g','Boundary');

%More intelligent classifier -->3rd classifier

K = 5; %neighbours to consider
BooleanNeighbour_Streaming = zeros(1,length(StreamingMean));
EyesCO = -1;

for i = 1:length(Boolean_Streaming)
    if i <= K
        BooleanNeighbour_Streaming(i)= Boolean_Streaming(i);
    else
        EyesCO = sum(Boolean_Streaming((i-K):(i-1)));
        if EyesCO <= K/2
            BooleanNeighbour_Streaming(i) = 0;
        else
            BooleanNeighbour_Streaming(i) = 1;
        end
    end
end

figure(7001)
gscatter(Time,StreamingMean,BooleanNeighbour_Streaming,'br','xo');
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');
hline(10,'g','Boundary');



%REPEAT THE MEAN FOR THE STREAMING
secondsToAnalyze = 1;%Insert number of seconds to consider -----> CAMBIAMIIIIIIIIIIIIIIIIIIIII!

index_start = 1;
index_end = secondsToAnalyze*fs;

roundSeconds = nSamples - mod(nSamples,secondsToAnalyze*fs);

StreamingMean2 = zeros(1,roundSeconds/(secondsToAnalyze*fs));

i=0;

for i = 1:length(StreamingMean2)
    StreamingMean2(i) = mean(Y(index_start:index_end));
    index_start = index_start + (secondsToAnalyze*fs);
    index_end = index_end + (secondsToAnalyze*fs);
end

tempIntervals = roundSeconds/(secondsToAnalyze*fs);
integerRoundSeconds = (roundSeconds/fs) - secondsToAnalyze;
Time = 0:secondsToAnalyze:integerRoundSeconds;

%PLOT THE DATA --> MEANS AND TIME
figure
plot(Time,StreamingMean2);

figure(8001)
scatter(Time,StreamingMean2);

%Create Vector with eyes closed and open basing on the mean
Boolean_Streaming = zeros(1,length(StreamingMean2));

for i = 1:length(StreamingMean2)
    if(StreamingMean2(i)<10)
        Boolean_Streaming(i) = 1; 
    else
        Boolean_Streaming(i) = 0;
    end
end

%K NEAREST NEIGHBOUR CLASSIFIER
K = 3; %neighbours to consider
BooleanNeighbour_Streaming = zeros(1,length(StreamingMean2));
EyesCO = -1;

for i = 1:length(Boolean_Streaming)
    if i <= K
        BooleanNeighbour_Streaming(i)= Boolean_Streaming(i);
    else
        EyesCO = sum(Boolean_Streaming((i-K):(i-1)));
        if EyesCO <= K/2
            BooleanNeighbour_Streaming(i) = 0;
        else
            BooleanNeighbour_Streaming(i) = 1;
        end
    end
end

figure(9001)
gscatter(Time,StreamingMean2,BooleanNeighbour_Streaming,'br','xo');
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');
hline(10,'g','Boundary');


%K NEAREST NEIGHBOUR CLASSIFIER 2 try
K = 6; %neighbours to consider
K1 = K + 1;
BooleanNeighbour_Streaming = zeros(1,length(StreamingMean2));
EyesCO = -1;

for i = 1:length(Boolean_Streaming)
    if i <= K1
        BooleanNeighbour_Streaming(i)= Boolean_Streaming(i);
    else
        EyesCO = sum(Boolean_Streaming((i-K):(i)));
        if EyesCO <= K1/2
            BooleanNeighbour_Streaming(i) = 0;
        else
            BooleanNeighbour_Streaming(i) = 1;
        end
    end
end

figure(90022)
gscatter(Time,StreamingMean2,BooleanNeighbour_Streaming,'br','xo');
vline(51958/fs,'r','Trigger1');
vline(82987/fs,'r','Trigger2');
hline(10,'g','Boundary');

%Save StreamingMean in .dat
csvwrite('NewArray.dat',StreamingMean2);
type NewArray.dat;








