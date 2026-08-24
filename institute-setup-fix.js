/* Institute bootstrap fix: avoid PostgREST .single() on the first insert/update. */
(function(){
  function client(){
    const url=localStorage.getItem('vd_url')||'';
    const key=localStorage.getItem('vd_key')||'';
    if(!url||!key) throw Error('Configure Supabase first');
    return window.supabase.createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true}});
  }
  window.saveSetup=async function(){
    try{
      const db2=client();
      const {data:{user}}=await db2.auth.getUser();
      if(!user) throw Error('Please login again.');
      const id=crypto.randomUUID();
      const payload={
        id,
        name:document.getElementById('in').value.trim(),
        phone:document.getElementById('phone').value.trim(),
        address:document.getElementById('addr').value.trim(),
        city:document.getElementById('city').value.trim(),
        state:document.getElementById('state').value.trim(),
        institute_type:document.getElementById('type').value,
        gst_enabled:document.getElementById('gst').value==='true',
        gstin:document.getElementById('gst').value==='true'?document.getElementById('gstin').value.trim():null
      };
      if(!payload.name) throw Error('Institute Name is required');
      const ins=await db2.from('institutes').insert(payload);
      if(ins.error) throw ins.error;
      const prof=await db2.from('profiles').update({institute_id:id,role:'owner'}).eq('id',user.id);
      if(prof.error) throw prof.error;
      const p=await db2.from('profiles').select('*').eq('id',user.id).maybeSingle();
      if(p.error) throw p.error;
      if(!p.data||p.data.institute_id!==id) throw Error('Institute was created, but owner profile could not be linked.');
      window.location.reload();
    }catch(e){
      const n=document.createElement('div'); n.className='toast'; n.textContent=e.message||String(e); document.body.appendChild(n); setTimeout(()=>n.remove(),3000);
    }
  };
})();
