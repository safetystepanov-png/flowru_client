bool isConfirmedCartSubmission({required bool submittedHere,required Map<String,dynamic>? checkout,required Map<String,dynamic>? intent,required Map<String,dynamic>? order}) {
 if (!submittedHere || checkout==null || intent==null || order==null) return false;
 final requestId=intent['request_id']?.toString();
 return requestId!=null && requestId.isNotEmpty && requestId==order['request_id']?.toString() && order['preorder_id']!=null;
}
