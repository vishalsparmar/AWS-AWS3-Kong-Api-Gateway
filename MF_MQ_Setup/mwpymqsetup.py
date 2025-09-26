---

## 8. Python Bridge App with pymqi

If you prefer Python over Java, you can use **pymqi** to implement the same bridging logic.

### 8.1 Install pymqi

```bash
pip install pymqi

import pymqi
import time

# Mainframe connection details
queue_manager = "MFQMGR"
channel = "APP.SVRCONN"
host = "10.10.10.5"
port = "1414"
conn_info = f"{host}({port})"
user = "userid"
password = "password"

# Queue names
local_send_queue = "MF.APP.OUT"   # Local queue (EKS QMGR)
local_recv_queue = "MF.APP.IN"    # Local queue (EKS QMGR)
remote_send_queue = "APP.REQ.Q"   # Remote MF queue
remote_recv_queue = "APP.RECV.Q"  # Remote MF queue

# Connect to mainframe MQ as client
qmgr = pymqi.QueueManager(None)
qmgr.connect_tcp_client(queue_manager, pymqi.CD(), channel, conn_info, user, password)

# Local queues will usually be accessed via another MQ client library
# For demo, here we'll just show mainframe interaction

def send_to_mainframe(message_text):
    """Send a message to MF queue via SVRCONN"""
    queue = pymqi.Queue(qmgr, remote_send_queue)
    queue.put(message_text.encode("utf-8"))
    queue.close()
    print(f"Sent to mainframe: {message_text}")

def receive_from_mainframe():
    """Receive messages from MF queue via SVRCONN"""
    queue = pymqi.Queue(qmgr, remote_recv_queue)
    try:
        msg = queue.get(wait=5000)  # 5s wait
        print(f"Received from mainframe: {msg.decode('utf-8')}")
        return msg.decode("utf-8")
    except pymqi.MQMIError as e:
        if e.comp == pymqi.CMQC.MQCC_FAILED and e.reason == pymqi.CMQC.MQRC_NO_MSG_AVAILABLE:
            return None
        else:
            raise
    finally:
        queue.close()

# Example loop
while True:
    # Example: forward local messages (mocked here) to MF
    send_to_mainframe("Hello from EKS Python Bridge!")

    # Example: fetch from MF and write to local (here just print)
    msg = receive_from_mainframe()
    if msg:
        print(f"Would normally forward to local queue: {msg}")

    time.sleep(5)

qmgr.disconnect()
