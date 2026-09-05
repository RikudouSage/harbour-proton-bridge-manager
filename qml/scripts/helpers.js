function safeCallerFactory(queue, page, additionalChecks) {
    return function(callable) {
        if (!additionalChecks) {
            additionalChecks = function() {
                return true;
            };
        }

        if (pageStack.busy || page.status !== PageStatus.Active || !additionalChecks()) {
            queue.push(callable);
        } else {
            callable();
        }
    };
}
