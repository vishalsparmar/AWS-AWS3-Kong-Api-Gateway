Perfect! Here’s a step-by-step setup for creating an EKS-side “bridge” to a mainframe MQ using your existing EKS distributed MQ QMGR and a JMS client, without requiring any changes on the mainframe.
1️⃣ Local Queue Manager Setup in EKS
Your EKS QMGR will handle local queues where your JMS app reads from and writes to.
Step 1 — Create Local Queues
/* Queue for sending messages to mainframe */
DEFINE QLOCAL(MF.APP.OUT) REPLACE

/* Queue for receiving messages from mainframe */
DEFINE QLOCAL(MF.APP.IN) REPLACE
MF.APP.OUT → messages your apps want to send to MF
MF.APP.IN → messages pulled from MF to local queues
No XMITQ or channels needed on EKS QMGR for client-only bridge.
2️⃣ JMS Client Application Setup
Your app acts as the bridge, connecting to the mainframe via SVRCONN.
Connection Parameters
Host/IP: Mainframe listener IP
Port: Mainframe listener port (usually 1414)
Queue Manager: MFQMGR
SVRCONN Channel: APP.SVRCONN
Queues: APP.REQ.Q (send), APP.RECV.Q (receive)
Authentication/TLS: if required
Step 2 — Sending Messages from EKS QMGR to Mainframe
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
Step 3 — Receiving Messages from Mainframe to EKS QMGR
Connection recvConnection = cf.createConnection("userid", "password");
Session recvSession = recvConnection.createSession(false, Session.AUTO_ACKNOWLEDGE);

// Pull messages from MF queue
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
3️⃣ How it Works
Step	Description
1	Local JMS apps put messages into MF.APP.OUT on EKS QMGR
2	JMS bridge app reads from MF.APP.OUT, sends to mainframe via SVRCONN channel
3	Mainframe processes messages and puts responses in APP.RECV.Q
4	JMS bridge app pulls from APP.RECV.Q and puts messages into MF.APP.IN local queue
5	Local JMS apps read responses from MF.APP.IN
This effectively acts as a bridge entirely on the EKS side.
4️⃣ Key Advantages
No mainframe configuration needed beyond existing SVRCONN channel.
Can be fully containerized in EKS.
Works for both send and receive.
All logic is inside your JMS app, using the local EKS QMGR queues for staging.
If you want, I can also provide a ready-to-use Kubernetes deployment snippet that runs this bridge app in EKS, connecting local distributed MQ queues to mainframe MQ.
Do you want me to do that?

You said:
yes
ChatGPT said:
Here’s a ready-to-use Kubernetes deployment setup for running a JMS bridge app in EKS, connecting your EKS distributed MQ queues to the mainframe MQ via SVRCONN.
1️⃣ Dockerfile for JMS Bridge App
FROM eclipse-temurin:17-jdk

# Add your compiled JMS bridge jar
COPY jms-bridge.jar /opt/jms-bridge/jms-bridge.jar

WORKDIR /opt/jms-bridge

# Run the JMS bridge
CMD ["java", "-jar", "jms-bridge.jar"]
jms-bridge.jar contains the code that reads from EKS QMGR queues and connects to mainframe SVRCONN channel.
2️⃣ Kubernetes Deployment YAML
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
3️⃣ Service (Optional, if other apps need to reach the bridge)
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
The service is optional if the bridge only interacts with local EKS QMGR queues internally.
4️⃣ How It Works
Local JMS apps in EKS put messages to MF.APP.OUT.
Bridge container reads from MF.APP.OUT, sends to mainframe APP.REQ.Q via SVRCONN.
Bridge also pulls messages from mainframe APP.RECV.Q and puts into MF.APP.IN.
Local apps read responses from MF.APP.IN.
5️⃣ Notes
Make sure your EKS MQ QMGR is reachable from the bridge container (same namespace/service or via MQ client connection).
Use ConfigMaps or Secrets for storing sensitive credentials instead of hardcoding them in deployment YAML.
TLS configuration can be added via MQ client SSL settings if required by mainframe.
You can scale the bridge container if throughput increases, but ensure message ordering is handled if needed.
If you want, I can also create a full ConfigMap + Secret example to store mainframe SVRCONN credentials and queue mappings, so your deployment is fully secure and Kubernetes-native.
Do you want me to do that?
