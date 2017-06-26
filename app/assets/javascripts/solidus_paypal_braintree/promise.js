SolidusPaypalBraintree.PromiseShim = {
  convertBraintreePromise: function(fn, args, context) {
    var jqPromise  = $.Deferred();

    args = args || [];
    context = context || this;

    args = args.concat(function(error, data) {
      if (error) {
        jqPromise.reject(error);
      } else {
        jqPromise.resolve(data);
      }
    });

    fn.apply(context, args);

    return jqPromise.promise();
  }
}
