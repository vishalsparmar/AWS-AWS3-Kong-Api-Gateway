Subject: Request for MQ-to-MQ connectivity between EKS MQ and Mainframe MQ
Hi [Team],
We are setting up bi-directional MQ communication between our EKS-hosted MQ Queue Manager (EKSQMGR) and the mainframe Queue Manager (MFQMGR).
To complete the configuration, could you please provide/confirm the following:
1. Channel Definitions
On MFQMGR (Mainframe side):
Define a Receiver channel to accept messages from EKS:
DEFINE CHANNEL(TO.MFQMGR) CHLTYPE(RCVR) TRPTYPE(TCP)
Define a Sender channel to send messages to EKS:
DEFINE CHANNEL(TO.EKSQMGR) CHLTYPE(SDR) TRPTYPE(TCP) CONNAME('<EKS-IP>(1414)') XMITQ(EKSQMGR.XMITQ)
On EKSQMGR (EKS side):
We will configure matching Sender/Receiver channels for communication with MFQMGR.
2. Connection Details
Please confirm the IP address and port we should use to connect to MFQMGR.
Can MFQMGR connect outbound to our EKS QMgr (EKSQMGR) on port 1414?
3. Security
Is TLS required on these channels? If yes:
Which CipherSpec should we configure?
Do we need to exchange certificates?
Are there any CHLAUTH/RACF rules that we should account for (to allow EKSQMGR to connect)?
4. Queue Mappings
Which queues on MFQMGR should we send messages to?
Which queues on EKSQMGR should we expose for MFQMGR to send to?
5. Queue Manager Details
Please confirm the exact name of the mainframe QMgr (for RQMNAME).
Once we have this information, we’ll finalize the EKS side Sender/Receiver channel setup, transmission queues, and remote/local queues.
Thanks,
[Your Name]
