/* VidyaDesk enrollment workflow: student -> batch enrollment -> fee bill rows. */
window.VidyaFeeWorkflow=(()=>{
 async function enroll({db,instituteId,studentId,batchId,feePlanId,joinDate,discountAmount=0,notes=''}){
  if(!db)throw Error('Supabase is not configured');
  const {data:plan,error:pe}=await db.from('fee_plans').select('*').eq('id',feePlanId).single();if(pe)throw pe;
  const {data:enrollment,error:ee}=await db.from('batch_enrollments').insert({institute_id:instituteId,student_id:studentId,batch_id:batchId,fee_plan_id:feePlanId,join_date:joinDate,status:'active',discount_amount:discountAmount,notes}).select().single();if(ee)throw ee;
  const bills=window.VidyaFeeEngine.billsForEnrollment(enrollment,plan,joinDate,plan.basis==='course'?window.VidyaFeeEngine.addMonths(joinDate,12):window.VidyaFeeEngine.addMonths(joinDate,1));
  for(const b of bills){
   const gross=Number(b.gross_amount),discount=Number(b.discount_amount||0),net=Math.max(0,gross-discount);
   const {data:bill,error:be}=await db.from('fee_bills').insert({institute_id:instituteId,student_id:studentId,enrollment_id:enrollment.id,bill_number:window.VidyaFeeEngine.nextBillNumber('VD',Date.now()%100000),bill_date:b.period_start,due_date:b.due_date,period_start:b.period_start,period_end:b.period_end,gross_amount:gross,discount_amount:discount,net_amount:net,status:'unpaid',description:plan.name||'Tuition Fee'}).select().single();
   if(be)throw be;
   await db.from('fee_items').insert({institute_id:instituteId,bill_id:bill.id,description:plan.name||'Fee',quantity:1,rate:gross,amount:gross});
  }
  return enrollment;
 }
 async function recordPayment({db,instituteId,billId,amount,mode,reference,receivedBy}){
  const {data:bill,error:be}=await db.from('fee_bills').select('*').eq('id',billId).single();if(be)throw be;
  const {data:payments,error:pe}=await db.from('fee_payments').select('amount').eq('bill_id',billId);if(pe)throw pe;
  const paid=(payments||[]).reduce((n,p)=>n+Number(p.amount||0),0);const next=paid+Number(amount);
  if(next>Number(bill.net_amount))throw Error('Payment exceeds bill balance');
  const {data:p,error}=await db.from('fee_payments').insert({institute_id:instituteId,bill_id:billId,amount:Number(amount),payment_mode:mode,reference_no:reference||null,received_by:receivedBy}).select().single();if(error)throw error;
  const status=next>=Number(bill.net_amount)?'paid':next>0?'partial':'unpaid';await db.from('fee_bills').update({status}).eq('id',billId);return p;
 }
 return {enroll,recordPayment};
})();