// script for PhantomJS
var sys = require('system');
var url = sys.args[1];
var env = sys.env;
var username = env['MIOPON_USER'];
var password = env['MIOPON_PASSWORD'];

var page = require('webpage').create();

page.onResourceError = function(err) {
    page.reason = err.errorString;
};

page.open(url, function(status) {
    if (status !== 'success') {
	console.error('Error: ', page.reason);
	phantom.exit(1);
    }
    var s = page.evaluate(function(user, pass) {
        $('#username').val(user);
        $('#password').val(pass);
        return $('#submit').offset();
    }, username, password);
    page.sendEvent('click', s.left + 1, s.top + 1);

    // wait for XHR
    var st = new Date();
    var interval = setInterval(function() {
        var params = page.evaluate(function(interval) {
            return { access_token: token,
                     state: state,
                     token_type: tokenType,
                     expires_in: expiresIn };
        });
        if (params.access_token) {
            clearInterval(interval);
            console.log(JSON.stringify(params));
            phantom.exit();
        }
        if ((new Date()) - st > 5000) {
            // timeout
            clearInterval(interval);
            page.render('miopon_auth_error.png');
            phantom.exit(1);
        }
    }, 250);
});
