/* VidyaDesk UI cleanup + reference-style mobile branding + role normalization. */
(function(){
  window.auth=function(){
    document.body.innerHTML=css()+`<div class="auth"><div class="authbox"><div class="logo"><div class="vd-logo-mark">V</div><div class="vd-brand-name">VidyaDesk</div><div>Smart Institute Management</div></div><div class="tabs vd-role-tabs">${[['admin','Admin'],['teacher','Teacher'],['student','Student'],['parent','Parent'],['employee','Employee']].map(([r,label])=>`<button class="${S.role===r?'sel':''}" onclick="S.role='${r}';auth()">${label}</button>`).join('')}</div><div class="form" style="margin-top:14px"><div class="field full"><label>Email</label><input id="email" type="email" placeholder="name@example.com"></div><div class="field full"><label>Password</label><input id="pass" type="password"></div></div><button class="btn" style="width:100%;margin-top:12px" onclick="login()">Login</button><button class="btn alt" style="width:100%;margin-top:8px" onclick="register()">Create Owner Account</button><div class="muted" style="font-size:11px;margin-top:12px">VidyaDesk • Smart Institute Management</div></div></div>`;
  };
  window.shell=function(content){const ms=menus[S.role]||menus.student;return `<div class="top"><button onclick="drawer()">☰</button><b>VidyaDesk</b><span></span><button onclick="location.reload()">↻</button><button onclick="logout()">↪</button></div><div class="layout"><aside><div class="brand"><div class="vd-brand-name-small">VidyaDesk</div><small>${esc(S.institute?.name||'Smart Institute Management')}</small></div>${ms.map(x=>`<button class="nav ${S.page===x[0]?'on':''}" onclick="go('${x[0]}')">${x[1]}</button>`).join('')}</aside><main>${content}</main></div>`};
  window.saveSetup=async function(){try{if(!db)throw Error('Configure Supabase first');const id=crypto.randomUUID();const payload={id,name:$('in').value.trim(),phone:$('phone').value.trim(),address:$('addr').value.trim(),city:$('city').value.trim(),state:$('state').value.trim(),institute_type:$('type').value,gst_enabled:$('gst').value==='true',gstin:$('gst').value==='true'?$('gstin').value.trim():null};if(!payload.name)throw Error('Enter institute name');const{error}=await db.from('institutes').insert(payload);if(error)throw error;const{error:pe}=await db.from('profiles').update({institute_id:id,role:'admin'}).eq('id',S.profile.id);if(pe)throw pe;S.profile.institute_id=id;S.profile.role='admin';S.role='admin';const{data:i,error:ie}=await db.from('institutes').select('*').eq('id',id).maybeSingle();if(ie)throw ie;if(!i)throw Error('Institute was saved but could not be loaded');S.institute=i;render()}catch(e){toast(e.message)}};
  const originalHydrate=window.hydrate;window.hydrate=async function(){await originalHydrate();if(S.role==='owner')S.role='admin'};
  const style=document.createElement('style');style.textContent=`
    :root{--p:#e53935!important;--p2:#ef5350!important;--bg:#f7f7f7!important;--line:#e3e3e3!important;--text:#242424!important;--muted:#777!important}
    .top{background:linear-gradient(90deg,#d92323,#ef5350)!important}
    .hero{background:linear-gradient(135deg,#ef5350,#d92323)!important}
    .btn{background:#e53935!important}.btn.alt{color:#d92323!important;border-color:#ef9a9a!important;background:#fff!important}
    .nav.on,.nav:hover{background:#ffebee!important;color:#d92323!important}
    .brand strong{background:#e53935!important}
    .vd-role-tabs{grid-template-columns:repeat(5,1fr)!important}
    .logo{text-align:center;color:#d92323!important}
    .vd-logo-mark{width:68px;height:68px;margin:auto;border-radius:18px;background:#e53935;color:#fff;display:grid;place-items:center;font-size:30px;font-weight:900}
    .vd-brand-name{font-size:25px;font-weight:900;margin-top:8px;color:#d92323}
    .vd-brand-name-small{font-weight:900;font-size:20px;color:#d92323}
    .tabs button{background:#fff1f1!important}.tabs .sel{background:#e53935!important;color:#fff!important}
    @media(max-width:560px){.vd-role-tabs button{font-size:10px;padding:7px 2px}.authbox{padding:18px;border-radius:14px}.top{height:54px}main{padding:10px}.card{border-radius:12px}.quick button{padding:13px 8px}}
  `;document.head.appendChild(style);
  if(typeof S!=='undefined'){try{if(S.session)render();else auth()}catch(_){}}
})();