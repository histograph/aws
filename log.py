from datetime import datetime
from sys import stdout

# ZOMG .__/`\,-^~.__/`\,-^~.__/`\,-^~.__/`\,-^~
c = 0
progress = ".__/`\,-^~"
def whee():
    global c
    c += 1
    return progress[c % len(progress)]

# ok I'm calm again...

def log(msg):
    # log single "dot"
    if(len(msg) == 1):
        stdout.write(whee())
        stdout.flush()
    else:
        print("[%s] %s" % (datetime.now().isoformat(), msg))
