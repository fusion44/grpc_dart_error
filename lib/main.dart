import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

import 'lnd_rpc/lnd_rpc.dart';

import 'package:convert/convert.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ClientChannel _clientChannel;

  LightningClient _lightningClient;

  String error = "";

  String state = "Initializing";

  @override
  void initState() {
    _establishConnection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("State:", style: theme.textTheme.display1),
              Text(state),
              Container(height: 16.0),
              Text("Error:", style: theme.textTheme.display1),
              Text(error != "" ? error : "None (yet?)")
            ],
          ),
        ),
      ),
    );
  }

  _establishConnection() async {
    String cert = "";
    String macaroon = "";
    String host = "";

    ChannelCredentials creds = ChannelCredentials.secure(
      certificates: utf8.encode(
        """-----BEGIN CERTIFICATE-----
$cert
-----END CERTIFICATE-----""",
      ),
      onBadCertificate: (X509Certificate certificate, String host) {
        // Trust the certificate
        return true;
      },
    );

    CallOptions opts = CallOptions(
      metadata: {
        "macaroon": hex.encode(
          base64.decode(
            macaroon,
          ),
        )
      },
    );

    _clientChannel = ClientChannel(
      host,
      port: 10009,
      options: ChannelOptions(credentials: creds),
    );
    _lightningClient = LightningClient(
      _clientChannel,
      options: opts,
    );

    var infoRequest = GetInfoRequest();
    try {
      setState(() {
        state = "Awaiting for response";
        error = "";
      });

      var response = await _lightningClient.getInfo(infoRequest, options: opts);

      setState(() {
        state = "Node height: ${response.blockHeight}";
        error = "Got response, no error.";
      });
    } catch (e) {
      setState(() {
        state = "No Response, see error message.";
        error = e.toString();
      });
    }
  }
}
