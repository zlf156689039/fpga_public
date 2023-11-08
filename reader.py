import binascii
# import struct
import os
import matplotlib.pyplot as plt
import numpy as np
from scipy.fft import fft

frequency = 30e12
sample_rate = 10e6

data_path = 'C:/Users/dean/Desktop/adc_data.bin'

fid = open(data_path, 'rb')

data_out = []
num_chips = 128
num_rx = 4
num_tx = 2
adc_samples = 256
size = int(os.path.getsize(data_path) / 2)
num_chirp = int(size / adc_samples / num_rx)


def get_s16(val):
    if not val or val < 0x8000:
        return val
    else:
        return val - 0x10000


for i in range(size):
    data = fid.read(2)
    value = int.from_bytes(data, byteorder='little')
    num = str(binascii.hexlify(data), encoding='utf-8')
    data_unsigned = get_s16(value)
    data_out.append(data_unsigned)
fid.close()
data_out_array = np.array(data_out)
data_out_reshape = data_out_array.reshape(num_rx, adc_samples * num_chirp)


def my_fft(x, t):
    fft_x = fft(x)  # fft计算
    amp_x = abs(fft_x) / len(x) * 2  # 纵坐标变换
    label_x = np.linspace(0, int(len(x) / 2) - 1, int(len(x) / 2))  # 生成频率坐标
    amp = amp_x[0:int(len(x) / 2)]  # 选取前半段计算结果即可
    # amp[0] = 0                                              # 可选择是否去除直流量信号
    fs = 1 / (t[2] - t[1])  # 计算采样频率
    fre = label_x / len(x) * fs  # 频率坐标变换
    pha = np.unwrap(np.angle(fft_x))  # 计算相位角并去除2pi跃变
    return amp, fre, pha  # 返回幅度和频率


point_num = 256

t = np.linspace(0, 5 * np.pi, point_num)  # 时间坐标

data_fft = data_out_reshape[0][0:point_num]

print(data_out_reshape, data_out_reshape[0][0:point_num].shape)
amp, fre, pha = my_fft(data_fft, t)  # 调用函数
print(amp.shape, t.shape)

c = 3000000000
TC = 0.00006
B = 4000000000
d = amp * c * TC / (2 * B)

t_half = t[0:256:2]

# 绘图
plt.figure()
plt.plot(t, data_fft)
plt.title('Signal')
plt.xlabel('Time / s')
plt.ylabel('Intencity / cd')

plt.figure()
plt.plot(fre, amp)
plt.title('Amplitute-Frequence-Curve')
plt.ylabel('Amplitute / a.u.')
plt.xlabel('Frequence / Hz')

plt.figure()
plt.plot(t_half, d)
plt.title('distance')
plt.ylabel('distance / a.u.')
plt.xlabel('Frequence / Hz')
plt.show()