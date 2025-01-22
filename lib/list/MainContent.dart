import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainContent extends StatelessWidget {
  Function onPressed;
  MainContent(this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
            height: 20,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      "タイトル",
                      style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal),
                    ),
                  )),
            )),
        Expanded(
            child: Container(
          color: Colors.grey.shade300,
        )),
        Container(
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () => {onPressed()},
                  child: Padding(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text("詳細を見る"),
                      ),
                      padding: EdgeInsets.all(2)),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              side: BorderSide(color: Colors.red))))),
              Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: Text(
                      "2021/07/21",
                      style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal),
                    ),
                  ))
            ],
          ),
        )
      ],
    );
  }
}
