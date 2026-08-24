window.VidyaLeads=(()=>{
 async function list(db,instituteId,status){let q=db.from('leads').select('*').eq('institute_id',instituteId);if(status)q=q.eq('status',status);const{data,error}=await q.order('created_at',{ascending:false});if(error)throw error;return data||[]}
 async function followUp(db,row){const{data,error}=await db.from('lead_followups').insert(row).select().single();if(error)throw error;return data}
 async function summary(db,instituteId){const{data,error}=await db.from('leads').select('status').eq('institute_id',instituteId);if(error)throw error;return(data||[]).reduce((a,x)=>(a.total++,a[x.status]=(a[x.status]||0)+1,a),{total:0})}
 async function feesSummary(db,instituteId,from,to){let q=db.from('fee_bills').select('status,net_amount').eq('institute_id',instituteId);if(from)q=q.gte('bill_date',from);if(to)q=q.lte('bill_date',to);const{data,error}=await q;if(error)throw error;return(data||[]).reduce((a,x)=>{a.billed+=Number(x.net_amount||0);a[x.status]=(a[x.status]||0)+Number(x.net_amount||0);return a},{billed:0,paid:0,partial:0,unpaid:0})}
 return{list,followUp,summary,feesSummary};
})();