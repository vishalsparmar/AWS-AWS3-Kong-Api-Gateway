Here's what you need on each side:
On EKS MQ Queue Manager:
Channels:

Sender Channel - to send messages to mainframe
Receiver Channel - to receive messages from mainframe

Queues:

Transmission Queue - for outbound messages to mainframe (typically named after the remote queue manager)
Local queues - for receiving messages from mainframe
Remote queue definitions - pointing to queues on the mainframe

On Mainframe Queue Manager:
Channels:

Receiver Channel - to receive messages from EKS (matching the sender channel name from EKS)
Sender Channel - to send messages to EKS (matching the receiver channel name on EKS)

Queues:

Transmission Queue - for outbound messages to EKS
Local queues - for receiving messages from EKS
Remote queue definitions - pointing to queues on EKS

Key Configuration Points:

Channel Names: Sender channel name on one side must match receiver channel name on the other side
Connection Details: Configure proper hostname/IP and port for the EKS MQ service
Transmission Queue Naming: Usually named after the remote queue manager name
Network Connectivity: Ensure firewall rules allow MQ traffic (typically port 1414) between EKS cluster and mainframe
Security: Configure SSL/TLS if required, along with proper authentication

Example Channel Pair:

EKS → Mainframe: Sender channel "TO.MAINFRAME.QM"
Mainframe → EKS: Receiver channel "TO.MAINFRAME.QM"
Mainframe → EKS: Sender channel "TO.EKS.QM"
EKS → Mainframe: Receiver channel "TO.EKS.QM"

Would you like me to provide specific MQSC commands for creating these objects?RetryClaude can make mistakes. Please double-check responses.

 *********************************************For EKS Deployment: *********************************************
 ********************************************* *********************************************
Service Exposure: You'll need to expose your MQ service externally using either:

LoadBalancer service type
NodePort service
Ingress with TCP passthrough


Connection Name: Update the mainframe's CONNAME parameter with the actual external IP/hostname of your EKS MQ service
Network Policy: Ensure your EKS cluster allows inbound traffic on port 1414

For Mainframe:

Network Connectivity: Ensure the mainframe can reach your EKS cluster's external IP
User Permissions: Verify MCAUSER has appropriate permissions
Connection Name: Use the actual hostname/IP of the mainframe system

 ********************************************* ********************************************* ********************************************* *********************************************
  ********************************************* ***************************************mainframe testing ****** ********************************************* *********************************************
  Testing the Connection:
mqsc# Test message flow EKS → Mainframe
PUT MAINFRAME.APP.QUEUE
Test message from EKS

# Test message flow Mainframe → EKS  
PUT EKS.APP.QUEUE
Test message from Mainframe
Troubleshooting Commands:
mqsc# Check channel events
DISPLAY CHSTATUS(channelname) ALL
# View channel errors
DISPLAY QSTATUS(SYSTEM.CHANNEL.INITQ)


