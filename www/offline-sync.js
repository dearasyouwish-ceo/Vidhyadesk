window.VidyaOffline=(()=>{
 const KEY='vidyadesk_offline_queue_v2';
 function read(){try{return JSON.parse(localStorage.getItem(KEY)||'[]')}catch{return[]}}
 function enqueue(op){const q=read();q.push({...op,id:crypto.randomUUID(),created_at:new Date().toISOString()});localStorage.setItem(KEY,JSON.stringify(q));return q.length}
 function clear(){localStorage.removeItem(KEY)}
 async function flush(db){const q=read(),done=[];for(const op of q){try{const r=await db.from(op.table)[op.method||'insert'](op.payload);if(r.error)throw r.error;done.push(op.id)}catch(e){console.warn('VidyaDesk sync pending',op,e.message)}}if(done.length){const left=q.filter(x=>!done.includes(x.id));localStorage.setItem(KEY,JSON.stringify(left))}return{processed:done.length,pending:q.length-done.length}}
 function backup(payload){const blob=new Blob([JSON.stringify({version:2,created_at:new Date().toISOString(),data:payload},null,2)],{type:'application/json'});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=`vidyadesk-backup-${new Date().toISOString().slice(0,10)}.json`;a.click()}
 function restore(text){const x=JSON.parse(text);if(x.version!==2)throw Error('Unsupported VidyaDesk backup');return x.data||{}}
 return{read,enqueue,clear,flush,backup,restore};
})();