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
