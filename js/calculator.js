/*
JS code sample1 for defining custom APIs that integrate with azure
Created by Kartik Sawhney on 4/17/2016
Copyright 2016 Cargi. All rights reserved.
API call: https://cargiios.azure-mobile.net/api/calculator/add?a=1&b=2
API call2: https://cargiios.azure-mobile.net/api/calculator/add?a=5&b=3
API call3: https://cargiios.azure-mobile.net/api/calculator/table1
*/

    exports.register = function (api) {
        api.get('add', add);
        api.get('sub', subtract);
        api.get('table1', passwordFunc);
    }
    function add(req, res) {
        var result = parseInt(req.query.a) + parseInt(req.query.b);	
        res.send(200, { result: result });
    }
    function subtract(req, res) {
        var result = parseInt(req.query.a) - parseInt(req.query.b);
        res.send(200, { result: result });
    }

    function passwordFunc(req, res) {
        var itemTable = req.service.tables.getTable('Item');
        itemTable.where({text: 'Excellent item'}).read({success: returnFunc});
        function returnFunc(results) {
            if (results.length > 0) {
                res.send(200, results);
            } else {
                res.send(200, 1);
            }
        }
    }