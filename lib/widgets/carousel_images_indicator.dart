import 'package:australti_ecommerce_app/store_product_concept/store_product_data.dart';
import 'package:australti_ecommerce_app/theme/theme.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarouselImagesProductIndicator extends StatefulWidget {
  CarouselImagesProductIndicator({@required this.images, this.tag});
  final List<ImageProduct> images;

  final String tag;
  @override
  State<StatefulWidget> createState() {
    return _CarouselWithIndicatorState();
  }
}

class _CarouselWithIndicatorState
    extends State<CarouselImagesProductIndicator> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeChanger>(context).currentTheme;

    return Container(
      child: Stack(children: [
        CarouselSlider(
          items: List.generate(
            widget.images.length,
            (index) => Container(
              child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  child: Hero(
                    tag: widget.tag + '$index',
                    child: Container(
                      child: Image.network(
                        widget.images[index].url,
                        fit: BoxFit.contain,
                        height: MediaQuery.of(context).size.height * 0.36,
                      ),
                    ),
                  )),
            ),
          ),
          options: CarouselOptions(
              height: 300,
              aspectRatio: 16 / 6,
              viewportFraction: 0.9,
              initialPage: 0,
              enableInfiniteScroll: false,
              reverse: false,
              autoPlay: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              }),
        ),
        if (widget.images.length > 1)
          Positioned(
            child: Container(
              margin: EdgeInsets.only(top: 320),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.images.map((url) {
                  int index = widget.images.indexOf(url);
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: _current == index ? 10.0 : 8.0,
                    height: _current == index ? 10.0 : 8.0,
                    margin:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _current == index
                          ? currentTheme.accentColor
                          : Colors.grey.withOpacity(0.50),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ]),
    );
  }
}
