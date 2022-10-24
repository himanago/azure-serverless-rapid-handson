module.exports = async function (context, req) {
    context.bindings.document = JSON.stringify({
        partitionKey: 'default',
        name: req.body.name,
        message: req.body.message
    });

    context.res = {
        body: 'success'
    };
}