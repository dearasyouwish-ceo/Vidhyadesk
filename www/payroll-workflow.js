window.VidyaPayroll=(()=>{
 async function checkIn(db,row){const{data,error}=await db.from('staff_attendance').upsert({...row,check_in:new Date().toISOString(),status:'present'},{onConflict:'employee_id,attendance_date'}).select().single();if(error)throw error;return data}
 async function leaveRequest(db,row){const{data,error}=await db.from('leave_requests').insert({...row,status:'pending'}).select().single();if(error)throw error;return data}
 async function approveLeave(db,id,approvedBy,status='approved'){const{data,error}=await db.from('leave_requests').update({status,approved_by:approvedBy,approved_at:new Date().toISOString()}).eq('id',id).select().single();if(error)throw error;return data}
 async function recordSalary(db,row){const{data,error}=await db.from('salary_payments').insert(row).select().single();if(error)throw error;return data}
 return{checkIn,leaveRequest,approveLeave,recordSalary};
})();