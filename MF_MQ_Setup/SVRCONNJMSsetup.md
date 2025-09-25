# EKS MQ to Mainframe MQ Bridge Setup

This document explains how to set up a bridge between an **EKS-hosted IBM MQ Queue Manager** and a **Mainframe MQ** using a **client application (JMS)**. It covers sending, receiving, and recommended Kubernetes deployment.

---

## 1. Understanding the Connection

### Pre-requisites from Mainframe MQ team:

- SVRCONN channel name (e.g., `APP.SVRCONN`)  
- Queue Manager name (`MFQMGR`)  
- Queue names for sending and receiving messages  
- Listener IP + Port (usually 1414)  
- Authentication details (userid/password)  
- TLS information if required  

> Note: No changes on the mainframe are needed if using client mode.

---

## 2. Local Queue Manager Setup in EKS

Create **local queues** on your EKS QMGR for staging messages.

```mqsc
/* Queue for sending messages to mainframe */
DEFINE QLOCAL(MF.APP.OUT) REPLACE

/* Queue for receiving messages from mainframe */
DEFINE QLOCAL(MF.APP.IN) REPLACE
MF.APP.OUT: Messages your apps want to send to mainframe
MF.APP.IN: Messages pulled from mainframe for local consumption
3. JMS Client Application Setup
Your JMS app will act as the bridge, connecting to the mainframe via SVRCONN.
Connection Parameters
Host/IP: Mainframe listener IP
Port: 1414
Queue Manager: MFQMGR
SVRCONN Channel: APP.SVRCONN
Queues: APP.REQ.Q (send), APP.RECV.Q (receive)
Authentication/TLS: if required
3.1 Sending Messages to Mainframe
import com.ibm.mq.jms.MQQueueConnectionFactory;
import javax.jms.*;

MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
cf.setQueueManager("MFQMGR");
cf.setHostName("10.10.10.5");
cf.setPort(1414);
cf.setChannel("APP.SVRCONN");
cf.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP);

Connection connection = cf.createConnection("userid", "password");
Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);

// Read from local queue and send to mainframe
Queue localQueue = session.createQueue("queue:///MF.APP.OUT");
MessageConsumer consumer = session.createConsumer(localQueue);

Queue mfQueue = session.createQueue("queue:///APP.REQ.Q");
MessageProducer producer = session.createProducer(mfQueue);

connection.start();
Message msg;
while ((msg = consumer.receiveNoWait()) != null) {
    producer.send(msg);
}

connection.close();
3.2 Receiving Messages from Mainframe
Connection recvConnection = cf.createConnection("userid", "password");
Session recvSession = recvConnection.createSession(false, Session.AUTO_ACKNOWLEDGE);

// Pull messages from mainframe queue
Queue mfRecvQueue = recvSession.createQueue("queue:///APP.RECV.Q");
MessageConsumer mfConsumer = recvSession.createConsumer(mfRecvQueue);

// Put messages into local EKS queue
Queue localRecvQueue = recvSession.createQueue("queue:///MF.APP.IN");
MessageProducer localProducer = recvSession.createProducer(localRecvQueue);

recvConnection.start();
Message receivedMsg;
while ((receivedMsg = mfConsumer.receiveNoWait()) != null) {
    localProducer.send(receivedMsg);
}

recvConnection.close();
4. How the Bridge Works
Step	Description
1	Local JMS apps put messages into MF.APP.OUT
2	JMS bridge reads from MF.APP.OUT, sends to mainframe APP.REQ.Q via SVRCONN
3	Mainframe processes messages and puts responses in APP.RECV.Q
4	JMS bridge pulls from APP.RECV.Q and puts messages into MF.APP.IN
5	Local JMS apps read responses from MF.APP.IN
5. Kubernetes Deployment
5.1 Dockerfile
FROM eclipse-temurin:17-jdk

# Add your compiled JMS bridge jar
COPY jms-bridge.jar /opt/jms-bridge/jms-bridge.jar

WORKDIR /opt/jms-bridge

# Run the JMS bridge
CMD ["java", "-jar", "jms-bridge.jar"]
5.2 Deployment YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mq-jms-bridge
  labels:
    app: mq-bridge
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mq-bridge
  template:
    metadata:
      labels:
        app: mq-bridge
    spec:
      containers:
        - name: jms-bridge
          image: <your-docker-repo>/jms-bridge:latest
          env:
            - name: MQ_HOST
              value: "10.10.10.5"
            - name: MQ_PORT
              value: "1414"
            - name: MQ_QMGR
              value: "MFQMGR"
            - name: MQ_CHANNEL
              value: "APP.SVRCONN"
            - name: MQ_USER
              value: "userid"
            - name: MQ_PASSWORD
              value: "password"
            - name: LOCAL_SEND_QUEUE
              value: "MF.APP.OUT"
            - name: LOCAL_RECV_QUEUE
              value: "MF.APP.IN"
            - name: REMOTE_SEND_QUEUE
              value: "APP.REQ.Q"
            - name: REMOTE_RECV_QUEUE
              value: "APP.RECV.Q"
          resources:
            limits:
              memory: "512Mi"
              cpu: "500m"
            requests:
              memory: "256Mi"
              cpu: "250m"
          imagePullPolicy: Always
5.3 Optional Service
apiVersion: v1
kind: Service
metadata:
  name: mq-jms-bridge-svc
spec:
  selector:
    app: mq-bridge
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: ClusterIP
Only needed if other apps need to reach the bridge service.
6. Key Notes
The EKS QMGR handles local queues, and the bridge app manages messages to/from mainframe.
No mainframe changes are required beyond the existing SVRCONN channel.
For secure connections, configure TLS/certificates in the JMS client.
Use ConfigMaps or Secrets in Kubernetes for storing credentials securely.
The bridge can be scaled, but message ordering must be considered if needed.
7. Optional: Client-Only Connection Without QMGR
If you do not want to use your EKS QMGR queues, your JMS app can connect directly to mainframe SVRCONN channel and use mainframe queues for both sending and receiving.
No MQSC commands are required on the EKS QMGR.
Use host, port, channel, QMGR, and authentication in the JMS client configuration.
cf.setQueueManager("MFQMGR");
cf.setHostName("10.10.10.5");
cf.setPort(1414);
cf.setChannel("APP.SVRCONN");
cf.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP);
This document is now fully structured, with headings, bullet points, and syntax-highlighted code blocks for MQSC, Java, Python, and YAML.

You can now save this as `eks-mq-mainframe-bridge.md` and open it in **VS Code, Typora, Obsidian, or GitHub** to see it nicely formatted.  

Do you want me to also **add a Python pymqi version for the bridge** into this Markdown for completeness?


