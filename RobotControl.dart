import 'package:roslibdart/core/topic.dart';

class RobotControl {
  late Topic cmd_vel;

  RobotControl(this.cmd_vel);

  void move(double vertical, double horizontal,double speedFactor) {
    double linear_speed = -vertical * speedFactor * 0.5;
    if (vertical > 0) horizontal = -horizontal;
    double angular_speed = -horizontal;

    publishCmd(linear_speed, angular_speed);
  }

  Future<void> publishCmd(double _linear_speed, double _angular_speed) async {
    var linear = {'x': _linear_speed, 'y': 0.0, 'z': 0.0};
    var angular = {'x': 0.0, 'y': 0.0, 'z': _angular_speed};
    var twist = {'linear': linear, 'angular': angular};
    await cmd_vel.publish(twist);
    print('cmd published');
  }
}