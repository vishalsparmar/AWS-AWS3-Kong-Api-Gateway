import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.common.CommonConstants;
import javax.jms.*;

public class MainframeMQDirectClient {

    public static void main(String[] args) throws JMSException {
        // --- Mainframe MQ connection details ---
        String host = "10.10.10.5";         // Mainframe IP
        int port = 1414;                     // Listener port
        String channel = "APP.SVRCONN";      // Existing SVRCONN channel
        String queueManager = "MFQMGR";      // Mainframe Queue Manager
        String user = "userid";              // User (if required)
        String password = "password";        // Password (if required)

        // Queue names on mainframe
        String sendQueueName = "APP.REQ.Q";
        String receiveQueueName = "APP.RECV.Q";

        // --- Create connection factory ---
        MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
        cf.setHostName(host);
        cf.setPort(port);
        cf.setQueueManager(queueManager);
        cf.setChannel(channel);
        cf.setTransportType(CommonConstants.WMQ_CM_CLIENT); // Client connection

        // --- Connect ---
        Connection connection = cf.createConnection(user, password);
        Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);

        // --- Send a message to mainframe queue ---
        Queue sendQueue = session.createQueue("queue:///" + sendQueueName);
        MessageProducer producer = session.createProducer(sendQueue);

        TextMessage msg = session.createTextMessage("Hello Mainframe from Java client!");
        producer.send(msg);
        System.out.println("Message sent: " + msg.getText());

        // --- Receive a message from mainframe queue ---
        Queue receiveQueue = session.createQueue("queue:///" + receiveQueueName);
        MessageConsumer consumer = session.createConsumer(receiveQueue);

        connection.start(); // start receiving
        Message receivedMsg = consumer.receive(5000); // wait up to 5 seconds

        if (receivedMsg != null && receivedMsg instanceof TextMessage) {
            TextMessage textMsg = (TextMessage) receivedMsg;
            System.out.println("Message received: " + textMsg.getText());
        } else {
            System.out.println("No message received within timeout.");
        }

        // --- Cleanup ---
        producer.close();
        consumer.close();
        session.close();
        connection.close();
    }
}
