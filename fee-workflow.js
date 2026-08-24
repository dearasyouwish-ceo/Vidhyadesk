/* VidyaDesk enrollment workflow aligned to supabase_schema.sql. */
window.VidyaFeeWorkflow=(()=>{
 async function enroll({db,instituteId,studentId,batchId,feePlanId,joinDate,discountAmount=0}){
  if(!db)throw Error('Supabase is not configured');
  const {data:plan,error:pe}=await db.from('fee_plans').select('*').eq('id',feePlanId).single();if(pe)throw pe;
  const {data:enrollment,error:ee}=await db.from('batch_enrollments').insert({institute_id:instituteId,student_id:studentId,batch_id:batchId,fee_plan_id:feePlanId,join_date:joinDate,status:'active',discount_amount:Number(discountAmount||0)}).select().single();if(ee)throw ee;
  const horizon=plan.basis==='course'?window.VidyaFeeEngine.addMonths(joinDate,12):window.VidyaFeeEngine.addMonths(joinDate,1);
  for(const b of window.VidyaFeeEngine.billsForEnrollment(enrollment,plan,joinDate,horizon)){
   const gross=Number(b.gross_amount),discount=Number(b.discount_amount||0);
   const {data:bill,error:be}=await db.from('fee_bills').insert({institute_id:instituteId,student_id:studentId,enrollment_id:enrollment.id,batch_id:batchId,fee_plan_id:feePlanId,bill_number:window.VidyaFeeEngine.nextBillNumber('VD',Date.now()%100000),description:plan.name||'Tuition Fee',period_start:b.period_start,period_end:b.period_end,due_date:b.due_date,gross_amount:gross,discount_amount:discount,status:'pending'}).select().single();
   if(be)throw be;
   const {error:ie}=await db.from('fee_items').insert({institute_id:instituteId,bill_id:bill.id,description:plan.name||'Fee',amount:gross});if(ie)throw ie;
  }
  return enrollment;
 }
 async function recordPayment({db,instituteId,billId,amount,mode='cash',reference,receivedBy,accountId}){
  const {data:bill,error:be}=await db.from('fee_bills').select('*').eq('id',billId).single();if(be)throw be;
  const {data:payments,error:pe}=await db.from('fee_payments').select('amount').eq('bill_id',billId).eq('status','posted');if(pe)throw pe;
  const paid=(payments||[]).reduce((n,p)=>n+Number(p.amount||0),0),next=paid+Number(amount);
  if(Number(amount)<=0||next>Number(bill.net_amount))throw Error('Invalid payment amount or payment exceeds bill balance');
  const {data:p,error}=await db.from('fee_payments').insert({institute_id:instituteId,bill_id:billId,account_id:accountId||null,amount:Number(amount),payment_mode:mode,reference_no:reference||null,received_by:receivedBy||null}).select().single();if(error)throw error;
  await db.from('fee_bills').update({status:next>=Number(bill.net_amount)?'paid':'partial'}).eq('id',billId);return p;
 }
 return {enroll,recordPayment};
})();