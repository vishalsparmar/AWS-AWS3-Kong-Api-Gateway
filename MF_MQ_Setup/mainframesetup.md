What Queue Manager–to–Queue Manager needs
You will run an MQ queue manager in EKS (containerized IBM MQ). That QMgr and the mainframe QMgr will communicate over Sender/Receiver channels.
This requires a few pieces:


**********************From the mainframe MQ admin, ask for:******************
Their QMgr name (you have this already 👍).
A Receiver channel definition on their side, e.g.:
DEFINE CHANNEL(TO.EKSQMGR) CHLTYPE(RCVR) TRPTYPE(TCP)
They will need your EKS QMgr name and the channel name you want to use.
Which IP + Port they expect your EKS QMgr to connect to (probably still port 1414, but confirm).
TLS requirements:
CipherSpec (e.g., TLS_RSA_WITH_AES_256_CBC_SHA256)
Exchange of certificates if TLS is enforced.
Any security rules (CHLAUTH, CONNAUTH, RACF groups) that may restrict which partner QMgrs can connect.
Which queues you’ll target:
Typically, you’ll need a Remote Queue definition on your EKS QMgr that points to the mainframe queue, and they’ll need a corresponding XMITQ + local queue setup.


***********************On your EKS QMgr side, you’ll define:*************************
Sender channel:
DEFINE CHANNEL(TO.MFQMGR) CHLTYPE(SDR) TRPTYPE(TCP) CONNAME('MF.IP.ADDR(1414)') XMITQ(MFQMGR.XMITQ)
Transmission queue:
DEFINE QLOCAL(MFQMGR.XMITQ) USAGE(XMITQ)
Remote queue (to send to their target queue):
DEFINE QREMOTE(MF.TARGET.Q) RNAME('TARGET.QUEUE') RQMNAME('MFQMGR') XMITQ(MFQMGR.XMITQ)
This way, apps in EKS just put messages to MF.TARGET.Q (remote definition) on your local QMgr, and MQ takes care of delivery to the mainframe.

✅ Checklist to send to MQ Mainframe Team
You should ask them:
Receiver channel details
Please define a RCVR channel on your QMgr for my EKS QMgr.
What should we use as the channel name? (e.g., TO.EKSQMGR)
IP/Port
Confirm the IP and port I should point my SDR channel at.
TLS/security
Is TLS required? If yes, which CipherSpec?
Should we exchange certificates?
Any RACF/CHLAUTH rules to be aware of?
Queues
Which queues will I be sending to?
Do I also need to receive messages (so you define XMITQ + SDR back to me)?
Your QMgr name
(Confirm it matches what you already have — needed for RQMNAME).





*****************Mainfrmae side *****************************

MQ-to-MQ Bridge (Two-Way)
On Mainframe QMgr (MFQMGR)
Receiver channel (to accept from EKS):
DEFINE CHANNEL(TO.MFQMGR) CHLTYPE(RCVR) TRPTYPE(TCP)
Sender channel (to send to EKS):
DEFINE CHANNEL(TO.EKSQMGR) CHLTYPE(SDR) TRPTYPE(TCP) CONNAME('eks.ip.addr(1414)') XMITQ(EKSQMGR.XMITQ)
Transmission queue for sending:
DEFINE QLOCAL(EKSQMGR.XMITQ) USAGE(XMITQ)



*****************EKS SIDE ************************

On EKS QMgr (EKSQMGR)
Receiver channel (to accept from Mainframe):
DEFINE CHANNEL(TO.EKSQMGR) CHLTYPE(RCVR) TRPTYPE(TCP)
Sender channel (to send to Mainframe):
DEFINE CHANNEL(TO.MFQMGR) CHLTYPE(SDR) TRPTYPE(TCP) CONNAME('mf.ip.addr(1414)') XMITQ(MFQMGR.XMITQ)
Transmission queue:
DEFINE QLOCAL(MFQMGR.XMITQ) USAGE(XMITQ)
Remote queues pointing to target queues on MFQMGR:
DEFINE QREMOTE(MF.TARGET.Q) RNAME('ACTUAL.MF.QUEUE') RQMNAME('MFQMGR') XMITQ(MFQMGR.XMITQ)
Local queues for Mainframe to target on EKS:
DEFINE QLOCAL(EKS.TARGET.Q)

✅ Checklist to Ask MQ Mainframe Team
Here’s what you should request from them:
Channel setup
Define a Receiver (TO.MFQMGR) for my Sender.
Define a Sender (TO.EKSQMGR) pointing to my QMgr.
Connection details
Which IP + port do I use for MFQMGR?
Can they connect outbound to my EKS QMgr IP/port?
Security
Is TLS required? If so:
Which CipherSpec?
Do we need to exchange certificates?
Any CHLAUTH/RACF restrictions to allow my QMgr?
Queue mappings
Which queues on MFQMGR should I target?
Which queues on my side will they send to?
QMgr details
Confirm MF QMgr name (for RQMNAME).



*******************Flow Example**********************
EKS app → EKSQMGR → Remote queue (MF.TARGET.Q) → SDR channel → MFQMGR local queue.
Mainframe app → MFQMGR → Remote queue (EKS.TARGET.Q) → SDR channel → EKSQMGR local queue → EKS app consumes.




