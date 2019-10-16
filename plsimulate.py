import getopt
import sys
import math
import time
import os

usage = """Usage: plsimulate.py [-p period] [-m max_value] [-r peak_rate] [-d step_time] [-v]
"""

def main(argv):
    try:
        opts, args = getopt.getopt(argv,"hp:m:r:d:v")
    except getopt.GetoptError:
        print(usage)
        exit(1)
    max_value = 0.5
    period = 60.0
    rate = 0.1
    delta = 10
    verbose = False 
    for opt, arg in opts:
        if opt == '-h':
            print(usage)
            exit(0)
        elif opt == '-m':
            max_value = float(arg)
        elif opt == '-p':
            period = float(arg)
        elif opt == '-r':
            rate = float(arg)
        elif opt == '-d':
            delta = float(arg)
        elif opt == '-v':
            verbose = True
        else:
            print(usage)
            exit(1)
    print("period: {} sec, max_value: {}, rate: {}, delta: {}".format(period, max_value, rate, delta))
    cmd = "iptables -R FORWARD 1 -m statistic --mode random --probability {:.4f} -j DROP"
    v = math.sin((2*math.pi*rate+math.pi)*0.5)
    while True:
        t = time.time()
        x = t*math.pi*2/period
        y = max(v, math.sin(x)) - v
        y = y/(1-v)*max_value
        drop_rate = y
        if verbose:
            print('drop_rate: {:.4f}'.format(drop_rate))
        os.system(cmd.format(drop_rate))
        time.sleep(delta)


if __name__ == "__main__":
    main(sys.argv[1:])