import re
import paramiko

from log import log

def is_up(host):
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.client.AutoAddPolicy())
        client.connect(host, timeout=10)
        stdin, stdout, stderr = client.exec_command("echo")
        exit_status = stdout.channel.recv_exit_status()
        client.close()
        return (exit_status == 0)
    except:
        return False

def tail_cloudinit(host):
    log("Tailing cloud init log*")

    # Wait until cloud-init is finished to stop the tail
    cloudinit_finished = re.compile(r"Cloud-init[\.\s|\w]{7,14}finished", re.I)

    # runs for each line
    def is_finished(line):
        return r.match(line)

    # ssh login and tail the cloud init logfile
    client = paramiko.SSHClient()

    # Set SSH key parameters to auto accept unknown hosts
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    # Connect to the host
    client.connect(host, timeout=10)

    stdin, stdout, stderr = client.exec_command("tail -f /var/log/cloud-init-output.log")
    for line in stdout:
        log(' | ' + line[:-1])
        if cloudinit_finished.match(line):
            log("Cloud-init finished, server should be up... *rejoice!*")
            break