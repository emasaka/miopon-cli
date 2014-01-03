// script for PhantomJS
var sys = require('system');
var url = sys.args[1];
var env = sys.env;
var username = env['MIOPON_USER'];
var password = env['MIOPON_PASSWORD'];

var page = require('webpage').create();

page.open(url, function() {
    var s = page.evaluate(function(user, pass) {
        $('#username').val(user);
        $('#password').val(pass);
        return $('#submit').offset();
    }, username, password);
    page.sendEvent('click', s.left + 1, s.top + 1);

    // wait for XHR
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
    }, 250);
});
