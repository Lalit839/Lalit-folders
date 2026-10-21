import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

class RazorpayWebResult {
  final String? paymentId;
  final String? orderId;
  final String? signature;

  const RazorpayWebResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

Completer<void>? _scriptLoader;

Future<void> openRazorpayWebCheckout({
  required Map<String, dynamic> options,
  required void Function(RazorpayWebResult result) onSuccess,
  required void Function(String message) onFailure,
}) async {
  await _ensureCheckoutScript();
  final razorpayConstructor = globalContext.getProperty<JSFunction?>(
    'Razorpay'.toJS,
  );
  if (razorpayConstructor == null) {
    onFailure('Razorpay checkout could not be loaded.');
    return;
  }

  final checkoutOptions = _jsObjectFromMap(options);
  checkoutOptions.setProperty(
    'handler'.toJS,
    ((JSObject response) {
      onSuccess(
        RazorpayWebResult(
          paymentId: response
              .getProperty<JSString?>('razorpay_payment_id'.toJS)
              ?.toDart,
          orderId: response
              .getProperty<JSString?>('razorpay_order_id'.toJS)
              ?.toDart,
          signature: response
              .getProperty<JSString?>('razorpay_signature'.toJS)
              ?.toDart,
        ),
      );
    }).toJS,
  );
  final modalOptions = JSObject()
    ..setProperty(
      'ondismiss'.toJS,
      (() {
        onFailure('Payment was cancelled.');
      }).toJS,
    );
  checkoutOptions.setProperty('modal'.toJS, modalOptions);

  final checkout = razorpayConstructor.callAsConstructorVarArgs<JSObject>([
    checkoutOptions,
  ]);
  checkout.callMethod<JSAny?>('open'.toJS);
}

Future<void> _ensureCheckoutScript() {
  final existing = globalContext.getProperty<JSAny?>('Razorpay'.toJS);
  if (existing != null) return Future.value();
  final loader = _scriptLoader;
  if (loader != null) return loader.future;

  final completer = Completer<void>();
  _scriptLoader = completer;
  final script = web.HTMLScriptElement()
    ..src = 'https://checkout.razorpay.com/v1/checkout.js'
    ..async = true
    ..onload = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS
    ..onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError('Razorpay checkout script failed to load.');
      }
    }).toJS;
  web.document.head?.appendChild(script);
  return completer.future;
}

JSObject _jsObjectFromMap(Map<String, dynamic> map) {
  final object = JSObject();
  for (final entry in map.entries) {
    object.setProperty(entry.key.toJS, _toJsValue(entry.value));
  }
  return object;
}

JSAny? _toJsValue(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.toJS;
  if (value is int) return value.toJS;
  if (value is double) return value.toJS;
  if (value is num) return value.toDouble().toJS;
  if (value is bool) return value.toJS;
  if (value is Map<String, dynamic>) return _jsObjectFromMap(value);
  return value.toString().toJS;
}
