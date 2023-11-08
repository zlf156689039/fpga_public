fname='adc_data.bin';    %bin文件位置

rx_total=readDCA1000_1(fname);
rx0 = rx_total(1,:);
rx1 = rx_total(2,:);
rx2 = rx_total(3,:);
rx3 = rx_total(4,:);

rx0_first_chirp = rx0(1,1:256);
a=fft(rx0_first_chirp);
y=abs(a);
figure(1);
plot(abs(y));

Fs = 10000000;
N = 256;
delat = Fs/N;
x_axis = (0:N-1)*delat;
figure(2)
plot(x_axis,y)
d=x_axis*300000000*60*10^(-6)/(2*4000000000);

figure(3);
plot(d,y);

function [retVal] = readDCA1000_1(fileName)
numADCSamples = 256; % 每一个chirp的采样点数
numADCBits = 16; % 配置ADC寄存器的样本点大小，有12、14、16bits可选择，这里选择为16bits
numRX = 4; % 接收天线的数量，本例中接收天线为4
numLanes = 2; % 这个是LVDS 通道数，对于xW18xx等，通道数只有lane1、lane2两个
isReal = 1; % 接收的数据类型（实数或者虚数，实数设置为1，虚数设置为0）
fid = fopen(fileName,'r');%%读取文件

adcData = fread(fid, 'int16')%%将文件所有数据导出为一个N维列向量

% 下面这个if结构是用来将数据大小小于16bits时的一个补偿，
    if numADCBits ~= 16
        l_max = 2^(numADCBits-1)-1;
        adcData(adcData > l_max) = adcData(adcData > l_max) - 2^numADCBits;
    end 
    fclose(fid);
    fileSize = size(adcData, 1);
    if isReal
        numChirps = fileSize/numADCSamples/numRX;
        LVDS = zeros(1, fileSize);
        %create column for each chirp
        LVDS = reshape(adcData, numADCSamples*numRX, numChirps);
        LVDS = LVDS.';
    else
        numChirps = fileSize/2/numADCSamples/numRX;
        LVDS = zeros(1, fileSize/2);
        counter = 1;
            for i=1:4:fileSize-1
            LVDS(1,counter) = adcData(i) + sqrt(-1)*adcData(i+2); 
            LVDS(1,counter+1) = adcData(i+1)+sqrt(-1)*adcData(i+3); 
            counter = counter + 2;
            end
        LVDS = reshape(LVDS, numADCSamples*numRX, numChirps);  
        %each row is data from one chirp
        LVDS = LVDS.';
    end
        adcData = zeros(numRX,numChirps*numADCSamples);
        for row = 1:numRX
            for i = 1: numChirps
            adcData(row, (i-1)*numADCSamples+1:i*numADCSamples) = LVDS(i, (row-1)*numADCSamples+1:row*numADCSamples);
            end
        end
        retVal = adcData;
end
