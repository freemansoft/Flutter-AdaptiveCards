import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/elements/actions.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:video_player/video_player.dart';


mixin SeparatorElementMixin on AdaptiveElement {
  double topSpacing;
  bool separator;

  @override
  void loadTree() {
    super.loadTree();
    topSpacing = widgetState.resolver.resolveSpacing(adaptiveMap["spacing"]);
    separator = adaptiveMap["separator"] ?? false;
  }

  @override
  Widget generateWidget() {
    assert(separator != null,
    "Did you forget to call loadSeperator in this class?");
    return Column(
      children: <Widget>[
        separator
            ? Divider(
          height: topSpacing,
        )
            : SizedBox(
          height: topSpacing,
        ),
        super.generateWidget(),
      ],
    );
  }
}

mixin TappableElementMixin on AdaptiveElement {
  AdaptiveAction action;

  @override
  void loadTree() {
    super.loadTree();
    if (adaptiveMap.containsKey("selectAction")) {
      action = widgetState.cardRegistry.getAction(adaptiveMap["selectAction"], widgetState,null);
    }
  }

  @override
  Widget generateWidget() {
    return InkWell(
      onTap: action?.onTapped,
      child: super.generateWidget(),
    );
  }
}
mixin ChildStylerMixin on AdaptiveElement {
  String style;

  @override
  void loadTree() {
    super.loadTree();
    style = adaptiveMap["style"];
  }

  void styleChild() {
    // The container needs to set the style in every iteration
    if (style != null) {
      widgetState.resolver.setContainerStyle(style);
    }
  }
}


/// Usually the root element of every adaptive card.
///
/// This container behaves like a Column/ a Container
class AdaptiveCardElement extends AdaptiveElement {
  AdaptiveCardElement(Map adaptiveMap, widgetState,)
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  AdaptiveActionShowCard currentlyActiveShowCardAction;

  List<AdaptiveElement> children;

  List<AdaptiveAction> allActions;

  List<AdaptiveActionShowCard> showCardActions;

  Axis actionsOrientation;

  String backgroundImage;

  @override
  void loadTree() {
    super.loadTree();

    if (adaptiveMap.containsKey("actions")) {
      allActions = List<Map>.from(adaptiveMap["actions"])
          .map(
              (map) => widgetState.cardRegistry.getAction(map, widgetState, this))
          .toList();
      showCardActions = List<AdaptiveActionShowCard>.from(allActions
          .where((action) => action is AdaptiveActionShowCard)
          .toList());
    } else {
      allActions = [];
      showCardActions = [];
    }

    String stringAxis = widgetState.resolver.resolve("actions", "actionsOrientation");
    if (stringAxis == "Horizontal")
      actionsOrientation = Axis.horizontal;
    else if (stringAxis == "Vertical") actionsOrientation = Axis.vertical;

    children = List<Map>.from(adaptiveMap["body"])
        .map((map) => widgetState.cardRegistry.getElement(map, widgetState))
        .toList();

    backgroundImage = adaptiveMap['backgroundImage'];
  }

  @override
  Widget build() {
    List<Widget> widgetChildren =
    children.map((element) => element.generateWidget()).toList();

    // Adds the actions
    List<Widget> actionWidgets =
    allActions.map((action) => action.generateWidget()).toList();
    Widget actionWidget;
    if (actionsOrientation == Axis.vertical) {
      actionWidget = Column(
        children: actionWidgets,
        mainAxisAlignment: MainAxisAlignment.start,
      );
    } else {
      actionWidget = Row(
        children: actionWidgets,
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    }
    widgetChildren.add(actionWidget);

    if (currentlyActiveShowCardAction != null) {
      widgetChildren.add(currentlyActiveShowCardAction.card.build());
    }
    Widget result = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: widgetChildren,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );


    if(backgroundImage != null) {
      result = Stack(
        children: <Widget>[
          Positioned.fill(child: Image.network(backgroundImage, fit: BoxFit.cover,)),
          result,
        ],
      );
    }


    return result;
  }

  /// This is called when an [_AdaptiveActionShowCard] triggers it.
  void showCard(AdaptiveActionShowCard showCardAction) {
    if (currentlyActiveShowCardAction == showCardAction) {
      currentlyActiveShowCardAction = null;
    } else {
      currentlyActiveShowCardAction = showCardAction;
    }
    showCardAction.expanded = !showCardAction.expanded;
    showCardActions.where((it) => it != showCardAction).forEach((it) => () {
      it.expanded = false;
    }());
    widgetState.rebuild();
  }

  @override
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
    children?.forEach((it) => it.visitChildren(visitor));
    allActions?.forEach((it) => it.visitChildren(visitor));
    showCardActions?.forEach((it) => it.visitChildren(visitor));
  }
}

class AdaptiveTextBlock extends AdaptiveElement with SeparatorElementMixin {
  AdaptiveTextBlock(Map adaptiveMap, widgetState)
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  FontWeight fontWeight;
  double fontSize;
  Color color;
  Alignment horizontalAlignment;
  int maxLines;
  MarkdownStyleSheet markdownStyleSheet;

  @override
  void loadTree() {
    super.loadTree();
    fontSize = widgetState.resolver.resolveFontSize(adaptiveMap["size"]);
    fontWeight = widgetState.resolver.resolveFontWeight(adaptiveMap["weight"]);
    color =
        widgetState.resolver.resolveColor(adaptiveMap["color"], adaptiveMap["isSubtle"]);
    horizontalAlignment = loadAlignment();
    maxLines = loadMaxLines();
    markdownStyleSheet = loadMarkdownStyleSheet();
  }

  // TODO create own widget that parses _basic_ markdown. This might help: https://docs.flutter.io/flutter/widgets/Wrap-class.html
  Widget build() {
    return Align(
        alignment: horizontalAlignment,
        child: Text(
          text,
          style: TextStyle(
              fontWeight: fontWeight, fontSize: fontSize, color: color),
          maxLines: maxLines,
        )
      /* child: MarkdownBody(
        data: text,
        styleSheet: markdownStyleSheet,
      )*/
    );
  }

  String get text => adaptiveMap["text"];

  Alignment loadAlignment() {
    String alignmentString = adaptiveMap["horizontalAlignment"] ?? "left";
    switch (alignmentString) {
      case "left":
        return Alignment.centerLeft;
      case "center":
        return Alignment.center;
      case "right":
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  /// This also takes care of the wrap property, because maxLines = 1 => no wrap
  int loadMaxLines() {
    bool wrap = adaptiveMap["wrap"] ?? true;
    if (!wrap) return 1;
    // can be null, but that's okay for the text widget.
    return adaptiveMap["maxLines"];
  }

  /// TODO Markdown still has some problems
  MarkdownStyleSheet loadMarkdownStyleSheet() {
    TextStyle style =
    TextStyle(fontWeight: fontWeight, fontSize: fontSize, color: color);
    return MarkdownStyleSheet(
      a: style,
      blockquote: style,
      code: style,
      em: style,
      strong: style.copyWith(fontWeight: FontWeight.bold),
      p: style,
    );
  }
}

// TODO implement verticalContentAlignment
class AdaptiveContainer extends AdaptiveElement
    with SeparatorElementMixin, TappableElementMixin, ChildStylerMixin {
  AdaptiveContainer(Map adaptiveMap, widgetState)
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  List<AdaptiveElement> children;

  Color backgroundColor;

  @override
  void loadTree() {
    super.loadTree();
    children = List<Map>.from(adaptiveMap["items"]).map((child) {
      styleChild();
      return widgetState.cardRegistry.getElement(child, widgetState);
    }).toList();

    String colorString = widgetState.resolver.hostConfig["containerStyles"]
    [adaptiveMap["style"] ?? "default"]["backgroundColor"];
    backgroundColor = parseColor(colorString);
  }

  Widget build() {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: children.map((it) => it.generateWidget()).toList(),
        ),
      ),
    );
  }

  @override
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
    children?.forEach((it) => it.visitChildren(visitor));
    action?.visitChildren(visitor);
  }
}

class AdaptiveColumnSet extends AdaptiveElement with TappableElementMixin {
  AdaptiveColumnSet(Map adaptiveMap, RawAdaptiveCardState widgetState)
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  List<AdaptiveColumn> columns;

  @override
  void loadTree() {
    super.loadTree();
    // TODO handle case where there are no children elegantly
    columns = List<Map>.from(adaptiveMap["columns"])
        .map((child) => AdaptiveColumn(child, widgetState))
        .toList();
  }

  @override
  Widget build() {
    return Row(
      children:
      columns.map((it) => Flexible(child: it.generateWidget())).toList(),
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }

  @override
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
    columns?.forEach((it) => it.visitChildren(visitor));
    action?.visitChildren(visitor);
  }
}

class AdaptiveColumn extends AdaptiveElement
    with SeparatorElementMixin, TappableElementMixin, ChildStylerMixin {
  AdaptiveColumn(Map adaptiveMap, RawAdaptiveCardState widgetState)
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  List<AdaptiveElement> items;
  //TODO implement
  double width;

  //TODO fix style (column/example3)
  @override
  void loadTree() {
    super.loadTree();
    items = List<Map>.from(adaptiveMap["items"]).map((child) {
      styleChild();
      return widgetState.cardRegistry.getElement(child, widgetState);
    }).toList();
  }

  @override
  Widget build() {
    return Column(
      children: items.map((it) => it.generateWidget()).toList(),
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  @override
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
    items?.forEach((it) => it.visitChildren(visitor));
  }
}

class AdaptiveFactSet extends AdaptiveElement with SeparatorElementMixin {
  AdaptiveFactSet(Map adaptiveMap, RawAdaptiveCardState widgetState)
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  List<Map> facts;

  @override
  void loadTree() {
    super.loadTree();
    facts = List<Map>.from(adaptiveMap["facts"]).toList();
  }

  @override
  Widget build() {
    return Row(
      children: [
        Column(
          children: facts
              .map((fact) => Text(
            fact["title"],
            style: TextStyle(fontWeight: FontWeight.bold),
          ))
              .toList(),
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        SizedBox(
          width: 8.0,
        ),
        Column(
          children: facts.map((fact) => Text(fact["value"])).toList(),
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class AdaptiveImage extends AdaptiveElement with SeparatorElementMixin {
  AdaptiveImage(Map adaptiveMap, RawAdaptiveCardState widgetState )
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  Alignment horizontalAlignment;
  bool isPerson;
  Tuple<double, double> size;

  String _sizeDesciption;

  @override
  void loadTree() {
    super.loadTree();
    horizontalAlignment = loadAlignment();
    isPerson = loadIsPerson();
    size = loadSize();

    _sizeDesciption = adaptiveMap["size"] ?? "auto";
  }

  @override
  Widget build() {

    //TODO alt text
    Widget image = Image(image: NetworkImage(url));

    if (isPerson) {
      image = ClipOval(
        clipper: FullCircleClipper(),
        child: image,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minWidth: size == null? 0 : size.a,
            minHeight: size == null? 0 : size.a,
            maxHeight: size == null? double.infinity : size.b,
            maxWidth: size == null? double.infinity : size.b),
        child: Align(
          alignment: horizontalAlignment,
          child: image,
        ),
      ),
    );
  }

  Alignment loadAlignment() {
    String alignmentString = adaptiveMap["horizontalAlignment"] ?? "left";
    switch (alignmentString) {
      case "left":
        return Alignment.centerLeft;
      case "center":
        return Alignment.center;
      case "right":
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  bool loadIsPerson() {
    if (adaptiveMap["style"] == null || adaptiveMap["style"] == "default")
      return false;
    return true;
  }

  String get url => adaptiveMap["url"];

  Tuple<double, double> loadSize() {
    String sizeDescription = adaptiveMap["size"] ?? "auto";
    if(sizeDescription == "auto" || sizeDescription == "stretch") return null;
    int size = widgetState.resolver.resolve("imageSizes", sizeDescription);
    return Tuple(size.toDouble(), size.toDouble());
  }
}

class AdaptiveImageSet extends AdaptiveElement with SeparatorElementMixin {
  AdaptiveImageSet(Map adaptiveMap, RawAdaptiveCardState widgetState)
      : super(adaptiveMap: adaptiveMap, widgetState: widgetState,);

  List<AdaptiveImage> images;

  String imageSize;
  double maybeSize;

  @override
  void loadTree() {
    super.loadTree();
    images = List<Map>.from(adaptiveMap["images"])
        .map((child) =>
        AdaptiveImage(child, widgetState))
        .toList();

    loadSize();
  }

  @override
  Widget build() {
    return LayoutBuilder(builder: (context, constraints) {
      return Wrap(
        //maxCrossAxisExtent: 200.0,
        children: images
            .map((img) => SizedBox(
            width: calculateSize(constraints), child: img.generateWidget()))
            .toList(),
        //shrinkWrap: true,
      );
    });
  }

  double calculateSize(BoxConstraints constraints) {
    if (maybeSize != null) return maybeSize;
    if (imageSize == "stretch") return constraints.maxWidth;
    // Display a maximum of 5 children
    if (images.length >= 5) {
      return constraints.maxWidth / 5;
    } else if (images.length == 0) {
      return 0.0;
    } else {
      return constraints.maxWidth / images.length;
    }
  }

  void loadSize() {
    String sizeDescription = adaptiveMap["imageSize"] ?? "auto";
    if (sizeDescription == "auto") {
      imageSize = "auto";
      return;
    }
    if (sizeDescription == "stretch") {
      imageSize = "stretch";
      return;
    }
    int size = widgetState.resolver.resolve("imageSizes", sizeDescription);
    maybeSize = size.toDouble();
  }

  @override
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
    images?.forEach((it) => it.visitChildren(visitor));
  }
}

class AdaptiveMedia extends AdaptiveElement with SeparatorElementMixin {
  AdaptiveMedia(Map adaptiveMap, RawAdaptiveCardState widgetState)
      : super(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState);

  VideoPlayerController videoPlayerController;
  ChewieController controller;

  String sourceUrl;
  String postUrl;
  String altText;

  FadeAnimation imageFadeAnim =
  FadeAnimation(child: const Icon(Icons.play_arrow, size: 100.0));

  @override
  void loadTree() {
    super.loadTree();
    postUrl = adaptiveMap["poster"];
    sourceUrl = adaptiveMap["sources"][0]["url"];
    videoPlayerController = VideoPlayerController.network(sourceUrl);

    controller = ChewieController(
      aspectRatio: 3 / 2,
      autoPlay: false,
      looping: true,
      autoInitialize: true,
      placeholder:
      postUrl != null ? Center(child: Image.network(postUrl)) : SizedBox(),
      videoPlayerController: videoPlayerController,
    );

    widgetState.addDeactivateListener(() {
      controller.dispose();
      controller = null;
    });
  }

  @override
  Widget build() {
    return Chewie(controller: controller,);
  }
}