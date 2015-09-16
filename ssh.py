import paramiko

def is_up(host):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.client.AutoAddPolicy())
        ssh.connect(host, timeout=10)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("echo")
        exit_status = ssh_stdout.channel.recv_exit_status()
        return (exit_status == 0)
    except:
        return False

#print(is_up('ec2-54-93-142-207.eu-central-1.compute.amazonaws.com'));