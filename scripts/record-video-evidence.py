import os
import pathlib
import signal
import subprocess
import time

recording = None
started = 0

def stop(*_):
    global recording
    if recording is not None:
        recording.send_signal(signal.SIGINT)
        recording.wait(timeout=15)
        recording = None

def finish(*_):
    stop()
    raise SystemExit

signal.signal(signal.SIGTERM, finish)
log = pathlib.Path('build/Wire-WireUITests.log')
while not log.exists():
    time.sleep(0.1)
with log.open() as stream:
    while True:
        line = stream.readline()
        if 'VIDEO_EVIDENCE_START' in line and recording is None:
            recording = subprocess.Popen([
                'xcrun', 'simctl', 'io', os.environ['IOS_SIM_ID'],
                'recordVideo', '--codec=h264', 'video-evidence/group-video.mp4'
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            started = time.monotonic()
        if 'VIDEO_EVIDENCE_STOP' in line or (recording and time.monotonic() - started > 30):
            stop()
            break
        if not line:
            time.sleep(0.1)
