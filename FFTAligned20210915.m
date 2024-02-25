
InputSignal = ProcessedSample(1).Sequence(3).Data;              % Input from the processed stuff
SamplePeriod = ProcessedSample(1).Sequence(3).SamplingRate;     %
SampleRate   = 1/SamplePeriod;                                 % Calculate this
LengthRecord = length(InputSignal);


PinkFilterF = designfilt('highpassfir',...
'PassbandFrequency', 6/(SamplePeriod*LengthRecord),...
'StopbandFrequency',1/(SamplePeriod*LengthRecord),...
'PassbandRipple',0.5,...
'StopbandAttenuation',20,...
'SampleRate',SampleRate,....
'DesignMethod','kaiserwin');

PinkFilterI = designfilt('highpassiir',...
'FilterOrder',4, ...
'PassbandFrequency',1/(SamplePeriod*LengthRecord),...
'PassbandRipple',0.5,...
'SampleRate',SampleRate);

%fvtool (PinkFilterF);


UpdatedTime = (0:LengthRecord-1)*SamplePeriod;
UpdatedNoise = InputSignal - min(InputSignal);  
UpdateNoiseF = filtfilt(PinkFilterF,UpdatedNoise);
UpdateNoiseI = filtfilt(PinkFilterI,UpdatedNoise);

ExpFitNoise = fit (UpdatedTime.',UpdatedNoise.','exp1')
UpdateNoiseE = UpdatedNoise - ExpFitNoise.a*exp(ExpFitNoise.b*UpdatedTime);

ArbFit7 = fittype ('a + b*x + c*(x+g)^d + e*exp(f*x)');
ArbFit5 = fittype ('a + b*x + c*(x+g)^d');

ArbFit5Noise = fit (UpdatedTime.',UpdatedNoise.',ArbFit5,'StartPoint', [0.01,0.01,0.01,-1,SamplePeriod/100],'lower', [-1,-1,-1,-2,1e-12], 'upper', [1,1,1,0,SamplePeriod/10])
UpdateNoise5 = UpdatedNoise - ArbFit5Noise.a - ArbFit5Noise.b*UpdatedTime - ArbFit5Noise.c*(UpdatedTime+2e-5).^ArbFit5Noise.d;

StartVector = [ArbFit5Noise.a, ArbFit5Noise.b,ArbFit5Noise.c, ArbFit5Noise.d, ExpFitNoise.a, ExpFitNoise.b, ArbFit5Noise.g];
%StartVector = [0,0,0,-1,0,-1,SamplePeriod/10];
ArbFitNoise7 = fit (UpdatedTime.',UpdatedNoise.',ArbFit7,'StartPoint', StartVector, 'lower', [-1,-1,-1,-2,-1,-5,1e-12], 'upper', [1,1,1,0,1,0,SamplePeriod/10])
UpdateNoise7 = UpdatedNoise - ArbFitNoise7.a - ArbFitNoise7.b*UpdatedTime - ArbFitNoise7.c*(UpdatedTime+2e-5).^ArbFitNoise7.d - ArbFitNoise7.e*exp(ArbFitNoise7.f*UpdatedTime);


figure
plot(UpdatedTime,UpdatedNoise);
hold on
plot(UpdatedTime,UpdateNoiseF);
hold on
plot(UpdatedTime,UpdateNoiseI);
hold on
plot(UpdatedTime,UpdateNoiseE);
hold on
plot(UpdatedTime,UpdateNoise5);
hold on
plot(UpdatedTime,UpdateNoise7);
legend('NoFilter','FFilter','IFilter','ExpFit','ArbFit5','ArbFit7');
hold off

NoisedFFT = fft(UpdatedNoise);
NoiseFFFT = fft(UpdateNoiseF);
NoiseIFFT = fft(UpdateNoiseI);
NoiseEFFT = fft(UpdateNoiseE);
Noise5FFT = fft(UpdateNoise5);
Noise7FFT = fft(UpdateNoise7);
FreqDom = 0.5*(0:length(NoisedFFT)-1)*SampleRate/length(NoisedFFT);
LogFreqDom = log10(FreqDom);

figure
plot(LogFreqDom, abs(NoisedFFT));
hold on
plot(LogFreqDom, abs(NoiseFFFT));
hold on
plot(LogFreqDom, abs(NoiseIFFT));
hold on
plot(LogFreqDom, abs(NoiseEFFT));
hold on
plot(LogFreqDom, abs(Noise5FFT));
hold on
plot(LogFreqDom, abs(Noise7FFT));
legend('NoFilter','FFilter','IFilter','ExpFit','ArbFit5','ArbFit7');
hold off

figure
plot(FreqDom, abs(NoisedFFT));
hold on
plot(FreqDom, abs(NoiseFFFT));
hold on
plot(FreqDom, abs(NoiseIFFT));
hold on
plot(FreqDom, abs(NoiseEFFT));
hold on
plot(FreqDom, abs(Noise5FFT));
hold on
plot(FreqDom, abs(Noise7FFT));
legend('NoFilter','FFilter','IFilter','ExpFit','ArbFit5','ArbFit7');
hold off

clear SampleRate;
clear SamplePeriod;
clear LengthRecord;
clear UpdatedNoise;
clear UpdateFNoise;
clear UpdateINoise;
clear InputSignal;
clear UpdatedNoise;