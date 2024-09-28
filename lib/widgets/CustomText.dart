import 'package:flutter/material.dart' show BuildContext, Color, FontStyle, FontWeight, StatelessWidget, Text, TextStyle, VoidCallback, Widget;
class CustomText extends StatelessWidget{
  final String TxtName;
  final double? Txtsize;
  final Color? TxtColor;
  final String? TxtFamily;
  final VoidCallback? Txtcallback;
  final FontWeight? Txtfontweight;
  final FontStyle? TxtfontStyle;
  const CustomText(
      {super.key,
        required this.TxtName,
        this.Txtsize=20,
        this.TxtColor,
        this.TxtFamily='RobotSlab',
        this.Txtcallback,
        this.Txtfontweight=FontWeight.w600,
        this.TxtfontStyle,});

  @override
  Widget build(BuildContext context) {
    return  Text(TxtName,
      style:
      TextStyle(fontFamily: TxtFamily,fontSize: Txtsize,fontWeight:Txtfontweight,fontStyle:TxtfontStyle ,color: TxtColor),
    );
  }


}