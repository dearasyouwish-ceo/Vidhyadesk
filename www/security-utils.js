window.VidyaSecurity=(()=>{
 const roles={owner:['*'],admin:['*'],teacher:['attendance:write','homework:write','marks:write','material:write'],student:['portal:read','learning:read'],parent:['portal:read','fees:read','attendance:read'],employee:['attendance:self','leave:self']};
 function can(role,permission){const p=roles[role]||[];return p.includes('*')||p.includes(permission)}
 async function log(db,row){const{data,error}=await db.from('activity_logs').insert(row).select().single();if(error)throw error;return data}
 function hashPin(pin){let h=2166136261;for(const c of String(pin))h=Math.imul(h^c.charCodeAt(0),16777619);return (h>>>0).toString(16)}
 function verifyPin(pin,hash){return hashPin(pin)===hash}
 return{can,log,hashPin,verifyPin};
})();