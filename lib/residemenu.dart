/**
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * createTime: 2018-5-9 21:13
 */

library residemenu;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef void OnOpen(bool isLeft);
typedef void OnClose();
typedef void OnOffsetChange(double offset);

enum ScrollDirection { LEFT, RIGHT, BOTH }

class ResideMenu extends StatefulWidget {
  // your content View
  final Widget child;

  final ScrollDirection direction;
  //left or right Menu View
  final Widget leftView, rightView;
  //shadow elevation
  final double elevation;
  // it will control the menu Action,such as openMenu,closeMenu
  MenuController controller;
  // used to set bottom bg and color
  final BoxDecoration decoration;

  final OnOpen onOpen;

  final OnClose onClose;

  final OnOffsetChange onOffsetChange;

  ResideMenu(
      {@required this.child,
      this.leftView,
      this.rightView,
      this.decoration: const BoxDecoration(),
      this.direction: ScrollDirection.LEFT,
      this.elevation: 12.0,
      this.onOpen,
      this.onClose,
      this.onOffsetChange,
      this.controller,
      Key key})
      : assert(child != null),
        super(key: key);

  @override
  _ResideMenuState createState() => new _ResideMenuState();
}

class _ResideMenuState extends State<ResideMenu> with TickerProviderStateMixin {
  // the last move point
  double _lastRawX = 0.0;
  //determine width
  double _width = 0.0;
  //check if user scroll left,or is Right
  bool _isLeft = true;
  // this will controll ContainerAnimation
  AnimationController _contentController, _menuController;

  void _onScrollStart(DragStartDetails details) {
    _lastRawX = details.globalPosition.dx;
  }

  void _onScrollMove(DragUpdateDetails details) {
    double offset = (details.globalPosition.dx - _lastRawX) / _width * 2.0;
    _contentController.value += offset;
    _lastRawX = details.globalPosition.dx;
  }

  void _onScrollEnd(DragEndDetails details) {
    if (_contentController.value > 0.5) {
      if (widget.controller.openMenu(true)) {
        if (widget.onOpen != null) {
          widget.onOpen(true);
        }
      }
    } else if (_contentController.value < -0.5) {
      if (widget.controller.openMenu(false)) {
        if (widget.onOpen != null) {
          widget.onOpen(false);
        }
      }
    } else {
      if (widget.controller.closeMenu()) {
        if (widget.onClose != null) {
          widget.onClose();
        }
      }
    }
    _lastRawX = 0.0;
  }

  void _changeState(bool left) {
    if (_isLeft != left) {
      setState(() {
        _isLeft = left;
      });
    }
  }

  void _init() {
    if(widget.controller==null)
    widget.controller = new MenuController();
    _menuController =
    new AnimationController(vsync: this, lowerBound: 1.0, upperBound: 2.0)
      ..addListener(() {
        if (widget.onOffsetChange != null) {
          widget.onOffsetChange(_menuController.value);
        }
      });

    _contentController = new AnimationController(
        lowerBound: widget.direction == ScrollDirection.LEFT ? 0.0 : -1.0,
        upperBound: widget.direction == ScrollDirection.RIGHT ? 0.0 : 1.0,
        value: 0.0,
        vsync: this,
        duration: const Duration(milliseconds: 300))
      ..addListener(() {
        if (_contentController.value > 0.0) {
          _changeState(true);
        } else {
          _changeState(false);
        }
      })
      ..addListener(() {
        _menuController.value = 2.0 - _contentController.value.abs();
      });
    widget.controller._aniController =_contentController;
  }

  @override
  void initState() {
    // TODO: implement initState
    _init();
//    if (widget.controller == null) {
//      widget.controller = new MenuController();
//    }
//    widget.controller._bind(_contentController);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _menuController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(builder: (context, cons) {
      _width = cons.biggest.width;
      return new GestureDetector(
        onHorizontalDragStart: _onScrollStart,
        onHorizontalDragUpdate: _onScrollMove,
        onHorizontalDragEnd: _onScrollEnd,
        child: new Stack(
          children: <Widget>[
            new Container(
              decoration: widget.decoration,
            ),
            new _MenuTransition(
              valueControll: _menuController,
              child: new Container(
                child: new Align(
                  child: _isLeft ? widget.leftView : widget.rightView,
                  alignment: _isLeft ? Alignment.topLeft : Alignment.topRight,
                ),
              ),
            ),
            new GestureDetector(
              onTap: () {
                widget.controller.closeMenu();
              },
              child: new _ContentTransition(
                  child: new Container(
                    child: widget.child,
                    decoration: new BoxDecoration(boxShadow: <BoxShadow>[
                      new BoxShadow(
                        color: const Color(0xcc000000),
                        offset: const Offset(-2.0, 2.0),
                        blurRadius: widget.elevation * 0.66,
                      ),
                      new BoxShadow(
                        color: const Color(0x80000000),
                        offset: const Offset(0.0, 3.0),
                        blurRadius: widget.elevation,
                      ),
                    ]),
                  ),
                  menuOffset: _contentController),
            )
          ],
        ),
      );
    });
  }
}

class _MenuTransition extends AnimatedWidget {
  final Widget child;

  _MenuTransition(
      {@required this.child,
      @required Animation<double> valueControll,
      Key key})
      : super(key: key, listenable: valueControll);

  Animation<double> get valueControll => listenable;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return new LayoutBuilder(builder: (context, cons) {
      double width = cons.biggest.width;
      double height = cons.biggest.height;
      final Matrix4 transform = new Matrix4.identity()
        ..scale(valueControll.value.abs(), valueControll.value.abs(), 1.0);
      return new Opacity(
        opacity: 2.0 - valueControll.value,
        child: new Transform(
            transform: transform,
            child: child,
            origin: new Offset(width / 2, height / 2)),
      );
    });
  }
}

class _ContentTransition extends AnimatedWidget {
  final Widget child;

  _ContentTransition(
      {@required this.child, @required Animation<double> menuOffset, Key key})
      : super(key: key, listenable: menuOffset);

  Animation<double> get menuOffset => listenable;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return new LayoutBuilder(builder: (context, cons) {
      double width = cons.biggest.width;
      double height = cons.biggest.height;
      double val = menuOffset.value;
      final Matrix4 transform = new Matrix4.identity()
        ..scale(1.0 - 0.25 * val.abs(), 1 - 0.25 * val.abs(), 1.0)
        ..translate(val * 0.8 * width);
      ;
      return new Transform(
          transform: transform,
          child: child,
          origin: new Offset(width / 2, height / 2));
    });
  }
}

class MenuController {
  AnimationController _aniController;
  bool _isOpen = false;

  bool openMenu(left) {
    _aniController.animateTo(left ? 1.0 : -1.0);
    if (!isOpen) {
      _isOpen = true;
      return true;
    }
    return false;
  }

  bool closeMenu() {
    _aniController.animateTo(0.0);
    if (isOpen) {
      _isOpen = false;
      return true;
    }
    return false;
  }

  bool get isOpen => _isOpen;
}
