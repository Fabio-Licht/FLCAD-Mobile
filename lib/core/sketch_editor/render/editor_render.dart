import '../models/editor_models.dart';

class SketchRenderStyle {
  const SketchRenderStyle(this.color, {this.width = 1, this.dashed = false});
  final int color;
  final double width;
  final bool dashed;
}

class SketchStylePalette {
  static const styles = <SketchVisualState, SketchRenderStyle>{
    SketchVisualState.normal: SketchRenderStyle(0xffdddddd),
    SketchVisualState.construction: SketchRenderStyle(0xff5599ff, dashed: true),
    SketchVisualState.reference: SketchRenderStyle(0xffaa77dd, dashed: true),
    SketchVisualState.driven: SketchRenderStyle(0xffaaaaaa),
    SketchVisualState.driving: SketchRenderStyle(0xffeeee44),
    SketchVisualState.selected: SketchRenderStyle(0xff22ccff, width: 2),
    SketchVisualState.hover: SketchRenderStyle(0xff66eeff, width: 2),
    SketchVisualState.preselected: SketchRenderStyle(0xff88bbff),
    SketchVisualState.conflicting: SketchRenderStyle(0xffff3333, width: 2),
    SketchVisualState.suppressed: SketchRenderStyle(0xff777777, dashed: true),
    SketchVisualState.disabled: SketchRenderStyle(0xff555555),
    SketchVisualState.locked: SketchRenderStyle(0xffffaa33),
    SketchVisualState.overdefined: SketchRenderStyle(0xffff2244, width: 2),
    SketchVisualState.underdefined: SketchRenderStyle(0xff4488ff),
  };
}
