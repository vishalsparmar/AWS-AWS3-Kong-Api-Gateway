Option 1: Direct Scaling (Simpler)
Your JMS app directly connects to mainframe and scales horizontally
Pros:

Simpler architecture
Lower latency
Fewer moving parts
Direct backpressure from mainframe

Cons:

Limited by mainframe connection limits
Harder to implement complex routing
Mainframe becomes single point of failure


***********************************************
Option 2: Local EKS Queue Manager (Recommended for High Scale)
Push to local EKS MQ → Multiple pods process
Pros:

Better decoupling
Higher scalability potential
Local queue buffering
Better fault tolerance
Complex message routing possible

Cons:

More complex setup
Additional infrastructure
Slight latency overhead

Architecture:
Mainframe MQ → EKS MQ (IBM MQ Container) → Multiple Processing Pods


**************************************************************

Why EKS Local QMgr is Best:
1. Scalability Benefits:

Unlimited pod scaling - Not constrained by mainframe connection limits
Queue-based autoscaling - Pods scale based on actual message backlog
Independent scaling - Processing capacity scales without affecting mainframe

2. Fault Tolerance:

Message buffering - Local queue acts as shock absorber for traffic spikes
Mainframe isolation - If mainframe goes down, messages already in local queue keep processing
Processing resilience - If processing pods fail, messages remain in queue

3. Performance Optimization:

Reduced mainframe load - Only bridge pod connects to mainframe
Parallel processing - Multiple pods consume simultaneously from local queue
Better throughput - Local network latency vs mainframe network calls

4. Operational Benefits:

Better monitoring - Clear visibility into queue depth and processing rates
Easier debugging - Messages persist locally for troubleshooting
Flexible routing - Can implement complex message routing/filtering locally


*****************************************************************************

A distributed MQ QMGR does not automatically act as a client bridge to another QMGR.
Why? Because:
A QMGR-to-QMGR connection is always peer-to-peer.
Both sides must define channels and transmission queues.
One side cannot just say “I’ll act as a client” to another QMGR.
The “client” role is reserved for applications, not other QMGRs.
🔹 So why is there confusion?
Because IBM MQ supports applications connecting as clients to a QMGR using SVRCONN.
Many people think “my EKS QMGR should be able to act as that client.”
But in reality, only apps (JMS, Python pymqi, MQI C apps, amqsput/amqsget, etc.) can use a SVRCONN.
Your EKS QMGR cannot directly use that SVRCONN to talk to the mainframe QMGR.
🔹 How “bridge” is achieved in practice
If you cannot change the mainframe QMGR (no SDR/RCVR/XMITQ), then the only way to “bridge” is to run a bridge process in EKS. That bridge:
Connects to your local EKS QMGR (server connection, no MQSERVER).
Connects as a client to the mainframe QMGR via SVRCONN channel.
Moves messages between them.
That’s why IBM and Red Hat provide things like:
IBM MQ Managed File Transfer (MFT)
MQ Bridge for HTTP / MQTT
Or you can write a custom bridge app in JMS, Python, or even shell scripts (amqsput/amqsget).
✅ Bottom line
A distributed MQ container is a full MQ queue manager server, not a bridge client.
It cannot use SVRCONN to connect itself to the mainframe QMGR.
To bridge, you must run an app or utility inside EKS that connects to both sides and moves messages.
