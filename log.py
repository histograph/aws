from datetime import datetime

def log(msg):
    print("[%s] %s" % (datetime.now().isoformat(), msg))