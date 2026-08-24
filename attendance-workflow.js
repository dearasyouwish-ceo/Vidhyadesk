/* Attendance workflow helpers. Provider calls remain abstract so institute WhatsApp/SMS configuration is preserved. */
window.VidyaAttendance=(()=>{
 async function markBatch({db,instituteId,batchId,markedBy,date,records}){
  const results=[];
  for(const r of records){
   const payload={institute_id:instituteId,batch_id:batchId,student_id:r.studentId,attendance_date:date,status:r.status,marked_by:markedBy,source:'manual',note:r.note||null};
   const{data,error}=await db.from('attendance').upsert(payload,{onConflict:'student_id,attendance_date'}).select().single();if(error)throw error;results.push(data);
  }
  return results;
 }
 function absentRecipients(records,students){const ids=new Set(records.filter(r=>r.status==='absent').map(r=>r.studentId));return students.filter(s=>ids.has(s.id)&&s.mobile).map(s=>({studentId:s.id,name:s.full_name,mobile:s.mobile,message:`Dear Parent, ${s.full_name} was marked absent today. Please contact VidyaDesk for details.`}));}
 async function logNotification(db,instituteId,recipient,message,channel='whatsapp'){const{data,error}=await db.from('notification_logs').insert({institute_id:instituteId,channel,recipient,template:'attendance_absent',payload:{message},status:'queued'}).select().single();if(error)throw error;return data}
 return {markBatch,absentRecipients,logNotification};
})();