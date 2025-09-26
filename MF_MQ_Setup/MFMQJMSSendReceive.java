import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.common.CommonConstants;
import javax.jms.*;

public class MainframeMQClient {

    public static void main(String[] args) throws JMSException {
        // Mainframe MQ connection details
        String host = "10.10.10.5";        // Mainframe IP
        int port = 1414;                    // Mainframe listener port
        String channel = "APP.SVRCONN";     // SVRCONN channel
        String queueManager = "MFQMGR";     // Mainframe Queue Manager
        String user = "userid";             // User (if required)
        String password = "password";       // Password (if required)

        // Queue names
        String sendQueueName = "APP.REQ.Q";
        String receiveQueueName = "APP.RECV.Q";

        // Create connection factory
        MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
        cf.setHostName(host);
        cf.setPort(port);
        cf.setQueueManager(queueManager);
        cf.setChannel(channel);
        cf.setTransportType(CommonConstants.WMQ_CM_CLIENT);

        // Connect
        Connection connection = cf.createConnection(user, password);
        Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);

        // Send message
        Queue sendQueue = session.createQueue("queue:///" + sendQueueName);
        MessageProducer producer = session.createProducer(sendQueue);

        TextMessage message = session.createTextMessage("Hello Mainframe!");
        producer.send(message);
        System.out.println("Message sent: " + message.getText());

        // Receive message
        Queue receiveQueue = session.createQueue("queue:///" + receiveQueueName);
        MessageConsumer consumer = session.createConsumer(receiveQueue);

        connection.start(); // start receiving
        Message receivedMsg = consumer.receive(5000); // wait up to 5s
        if (receivedMsg != null && receivedMsg instanceof TextMessage) {
            TextMessage textMsg = (TextMessage) receivedMsg;
            System.out.println("Message received: " + textMsg.getText());
        } else {
            System.out.println("No message received.");
        }

        // Cleanup
        producer.close();
        consumer.close();
        session.close();
        connection.close();
    }
}
