// A known order remains available in history; no financial operation is performed here.
bool detachPreviousCheckout(Map<String, dynamic> order) =>
    order['desired_action'] == 'cancel' ||
    const ['succeeded','cash_due','canceled','refunded','refund_pending'].contains(order['state']);
