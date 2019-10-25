import xml.etree.ElementTree as ET
import sys
import os
import datetime as dt
import subprocess
import logging
import signal
import time

logging.basicConfig(filename='logger.log', filemode='a', level=logging.INFO, 
                format='[%(asctime)s] %(levelname)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

def signal_handler(sig, frame):
    logging.info('Exit.')
    sys.exit(0)
signal.signal(signal.SIGINT, signal_handler)

header = ['timestamp', 
        'type',
        'protocol',
        'out_link',
        'out_packets',
        'out_bytes',
        'out_retrans',
        'in_link',
        'in_packets',
        'in_bytes',
        'in_retrans',
        'timeout',
        'state',
        'status',
        'deltatime',
        # 'when',
        ]

def get_local_ips():
    if os.name == 'nt':
        return []
    cmd = "ifconfig -a|grep 'inet '|awk '{print $2}'"
    ips = subprocess.check_output(cmd, shell=True).decode().split()
    return ips

def get_ip_quadruples(meta):
    src = meta.find('layer3').find('src').text
    dst = meta.find('layer3').find('dst').text
    sport, dport = '', ''
    if meta.find('layer4').find('sport') != None:
        sport = meta.find('layer4').find('sport').text
        dport = meta.find('layer4').find('dport').text
    return (src, sport, dst, dport)

def get_count(meta):
    counter = meta.find('counters')
    pks, bts, rts = None, None, None
    if counter != None:
        pks, bts = counter.find('packets').text, counter.find('bytes').text
        if counter.find('retrans') != None:
            rts = counter.find('retrans').text
    return pks, bts, rts

def main(protocols, blacklist):
    logging.info('Start Processing ...')
    print(','.join(header))
    ips = get_local_ips()
    cnt, pre_cnt = 0, 0
    start_time = time.time()
    for row in sys.stdin:
        if row[:5] != '<flow': continue
        data = {hd:'' for hd in header} 
        try:
            root = ET.fromstring(row)
            if 'type' in root.attrib:
                data['type'] = root.attrib['type'].upper()
            data['timestamp'] = dt.datetime.now()
            for child in root:
                if child.tag == 'meta':
                    drt = child.attrib['direction']
                    if  drt == 'original' or drt == 'reply':
                        src, sport, dst, dport = get_ip_quadruples(child)
                        pks, bts, rts = get_count(child)
                        if data['out_link']=='' and (src in ips or (ips==[] and drt=='original')):
                            direct = 'out'
                            data['%s_link'%direct] = '{}:{}>{}:{}'.format(src, sport, dst, dport)
                        else:
                            direct = 'in'
                            data['%s_link'%direct] = '{}:{}<{}:{}'.format(dst, dport, src, sport)
                        if pks is not None:
                            data['%s_packets'%direct] = pks
                            data['%s_bytes'%direct] = bts
                        if rts is not None:
                            data['%s_retrans'%direct] = rts
                        data['protocol'] = child.find('layer4').attrib['protoname']
                    elif child.attrib['direction'] == 'independent':
                        for key in ['state', 'timeout', 'deltatime']:
                            if child.find(key) != None:
                                data[key] = child.find(key).text
                        for status in ['unreplied', 'assured']:
                            if child.find(status) != None:
                                data['status'] = status.upper()
                # elif child.tag == 'when':
                #     tm = []
                #     for tag in ['year', 'month', 'day', 'hour', 'min', 'sec']:
                #         tm.append(int(child.find(tag).text))
                #     data['when'] = '%d%02d%02d%02d%02d%02d'%tuple(tm)
            if data['protocol'] not in protocols: continue
            ignore = False
            for s in blacklist:
                if s in data['out_link'] or s in data['in_link']: 
                    ignore = True
            if ignore: continue
            print(','.join([str(data[hd]) for hd in header]))
            cnt += 1
        except Exception as e:
            logging.warning('Error: {}'.format(row))
            logging.warning(e)
        if cnt % 1000 == 0:
            delta_time = time.time() - start_time 
            logging.info('Captured {} flows, {:.2f} flows/sec'.format(cnt, (cnt-pre_cnt)/delta_time))
            pre_cnt = cnt
    
if __name__ == "__main__":
    protocols = ['tcp']
    blacklist = ['127.0.0']
    main(protocols, blacklist)
