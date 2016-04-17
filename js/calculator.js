/*
JS code sample1 for defining custom APIs that integrate with azure
Created by Kartik Sawhney on 4/17/2016
Copyright 2016 Cargi. All rights reserved.
API call: https://cargiios.azure-mobile.net/api/calculator/add?a=1&b=2
API call2: https://cargiios.azure-mobile.net/api/calculator/add?a=5&b=3
*/

    exports.register = function (api) {
        api.get('add', add);
        api.get('sub', subtract);
    }
    function add(req, res) {
        var result = parseInt(req.query.a) + parseInt(req.query.b);
        res.send(200, { result: result });
    }
    function subtract(req, res) {
        var result = parseInt(req.query.a) - parseInt(req.query.b);
        res.send(200, { result: result });
    }
