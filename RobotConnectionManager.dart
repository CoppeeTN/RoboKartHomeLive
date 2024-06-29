import 'package:roslibdart/core/ros.dart';
import 'package:roslibdart/core/topic.dart';

class RobotConnectionManager {
  late Ros ros;
  late Topic camera;
  late Topic cmd_vel;
  late Topic odom;
  late Future<void> Function(Map<String, dynamic>) subscribeHandler;
  late Future<void> Function(Map<String, dynamic>) subscribeHandler2;

  RobotConnectionManager({
    required String url,
    required this.subscribeHandler,
    required this.subscribeHandler2
  }) {
    ros = Ros(url: url);
    camera = Topic(
      ros: ros,
      name: '/camera/image/compressed',
      type: 'sensor_msgs/CompressedImage',
      reconnectOnClose: true,
      queueSize: 10,
    );
    odom = Topic(
      ros: ros,
      name: '/odom',
      type: 'nav_msgs/Odometry',
      reconnectOnClose: true,
      queueSize: 10,
    );
    cmd_vel = Topic(
      ros: ros,
      name: '/cmd_vel',
      type: "geometry_msgs/Twist",
      reconnectOnClose: true,
      queueSize: 10,
    );
  }

  Future<void> connect() async {
    ros.connect();
    await camera.subscribe(subscribeHandler);
    await odom.subscribe(subscribeHandler2);
    await cmd_vel.advertise();
  }

  Future<void> disconnect() async {
    await odom.unsubscribe();
    await camera.unsubscribe();
    await cmd_vel.unadvertise();
    await ros.close();
  }
}