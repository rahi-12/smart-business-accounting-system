const transitions = {
    draft: ["sent", "cancelled"],
    sent: ["paid", "cancelled"],
    paid: [],
    cancelled: [],
};

function canTransition(from, to) {
    return Boolean(transitions[from] && transitions[from].includes(to));
}

function assertTransition(from, to) {
    if (!canTransition(from, to)) {
        const error = new Error(`Invoice cannot transition from ${from} to ${to}.`);
        error.code = "INVOICE_INVALID_TRANSITION";
        throw error;
    }
}

module.exports = {
    canTransition,
    assertTransition,
};
