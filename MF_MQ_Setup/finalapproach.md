You can set up an IBM MQ bridge from your containerized EKS queue manager to a mainframe queue manager (where you only have the SVRCONN channel, host, port, and queue names, and cannot change anything on the mainframe side) using standard MQ client connectivity and remote queue definitions in your EKS queue manager. Here’s how:

Setup Steps
1. MQ Client Connection to Mainframe (from EKS QM)
Your EKS-deployed queue manager should act as a client to the mainframe QM via the provided SVRCONN channel, host, and port.

No changes needed on the mainframe side if connection and permissions are already in place.

2. Define Remote Queues and XMIT Queue on EKS QM
In your EKS queue manager, define remote queues pointing to the mainframe destination queues and set up the appropriate XMITQ and sender channel.

Example MQSC definitions:

text
DEFINE QREMOTE('TO.MF.QUEUE') RNAME('DEST.QUEUE.ON.MF') RQMNAME('MFQM') XMITQ('TO.MFQM')
DEFINE QLOCAL('TO.MFQM') USAGE(XMITQ)
DEFINE CHANNEL('TO.MFQM.SDR') CHLTYPE(SDR) CONNAME('your.mf.host(mainframeport)') XMITQ('TO.MFQM') CHLTYPE(SDR) TRPTYPE(TCP)  MCAUSER('youruserid') SCYEXIT('')  // omit SCYEXIT or use as required
DEFINE CHANNEL('YOURSVRCONN') CHLTYPE(SVRCONN) TRPTYPE(TCP)
Replace 'TO.MF.QUEUE', 'DEST.QUEUE.ON.MF', 'MFQM', 'TO.MFQM.SDR', 'your.mf.host(mainframeport)', and 'YOURSVRCONN' accordingly.

3. Set Up Client Connection Table (optional)
You can use MQ environment variables or a CCDT file inside your container to point to the destination mainframe QM, using the server connection name, host and port.

4. Set Appropriate Channel Authentication
If your mainframe QM only exposes a specific SVRCONN and you have user credentials or SSL cert (as per your security), pass those credentials in CONNAME/MCAUSER or via your client application environment.

5. Containerization Tips
For Kubernetes/EKS, specify all these MQSC commands in your container initialization or via a configMap (as part of Helm/Operator or entrypoint script).

High-Level Diagram
text
[EKS Queue Manager: QM1]
 |
 |--(Sender Channel SDR/RemoteQ)
 |
[MF Host: Mainframe Queue Manager: MFQM]
   (listening on PORT, SVRCONN provided)
You CANNOT:
Create receiver channels on mainframe (no mainframe change allowed)

Alter CHLAUTH or queue manager config on MF

You CAN:
From your EKS QM (or containerized MQ Client app), create sender channel + remote queue pointed at the mainframe's SVRCONN host/port.

Send messages to mainframe queues using remote queue alias. The mainframe queue manager will process messages as received via the client connection.

References & Examples
[IBM MQ client bridge to mainframe guide]

[MQSC example for sender/receiver channel]

[Dockerized MQ client/channel config]

[IBM MQ Containers official tutorial]

In summary:

Create remote queue definitions and a sender channel on your EKS queue manager, targeting the mainframe’s SVRCONN, host, and port.

No changes are needed on the mainframe, as you’re connecting as a standard MQ client—just use the right user/channel/queue info.

Place relevant MQSC in your container’s setup.

Let me know if you want a container YAML/configMap template for this or a worked-out MQSC example using your values!

