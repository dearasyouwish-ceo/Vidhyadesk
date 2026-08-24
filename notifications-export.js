window.VidyaNotify=(()=>{
 async function queue(db,row){const{data,error}=await db.from('notification_logs').insert({...row,status:'queued'}).select().single();if(error)throw error;return data}
 async function bulk(db,instituteId,items,channel='whatsapp'){const rows=items.map(x=>({institute_id:instituteId,channel,recipient:x.mobile||x.recipient,template:x.template||'general',payload:x.payload||{message:x.message||''},status:'queued'}));if(!rows.length)return[];const{data,error}=await db.from('notification_logs').insert(rows).select();if(error)throw error;return data}
 function csv(rows){if(!rows.length)return '';const keys=[...new Set(rows.flatMap(r=>Object.keys(r)))];const q=v=>`"${String(v??'').replace(/"/g,'""')}"`;return [keys.join(','),...rows.map(r=>keys.map(k=>q(r[k])).join(','))].join('\n')}
 function downloadCsv(name,rows){const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([csv(rows)],{type:'text/csv'}));a.download=name;a.click()}
 return{queue,bulk,csv,downloadCsv};
})();