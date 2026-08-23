/* VidyaDesk UI cleanup: only Admin, Student and Teacher are shown on login. */
(function(){
  window.auth = function(){
    document.body.innerHTML = css()+`<div class="auth"><div class="authbox">
      <div class="logo"><div style="font-size:28px;font-weight:800">Vidhyadesk</div><div>Complete Coaching Institute Management</div></div>
      <div class="tabs vd-role-tabs">
        ${[['admin','Admin'],['student','Student'],['teacher','Teacher']].map(([r,label])=>`<button class="${S.role===r?'sel':''}" onclick="S.role='${r}';auth()">${label}</button>`).join('')}
      </div>
      <div class="form" style="margin-top:14px">
        <div class="field full"><label>Email</label><input id="email" type="email" placeholder="name@example.com"></div>
        <div class="field full"><label>Password</label><input id="pass" type="password"></div>
      </div>
      <button class="btn" style="width:100%;margin-top:12px" onclick="login()">Login</button>
      <button class="btn alt" style="width:100%;margin-top:8px" onclick="register()">Create Admin Account</button>
    </div></div>`;
  };
  window.shell = function(content){
    const ms = menus[S.role] || menus.student;
    return `<div class="top"><button onclick="drawer()">☰</button><b>Vidhyadesk</b><span></span><button onclick="location.reload()">↻</button><button onclick="logout()">↪</button></div><div class="layout"><aside><div class="brand"><div style="font-weight:800;font-size:18px">Vidhyadesk</div><small>${esc(S.institute?.name||'Education Management')}</small></div>${ms.map(x=>`<button class="nav ${S.page===x[0]?'on':''}" onclick="go('${x[0]}')">${x[1]}</button>`).join('')}</aside><main>${content}</main></div>`;
  };
  const style=document.createElement('style');
  style.textContent='.vd-role-tabs{grid-template-columns:repeat(3,1fr)!important}.logo{text-align:center}.brand{gap:8px}.brand small{display:block}';
  document.head.appendChild(style);
  if(typeof S!=='undefined'){try{if(S.session)render();else auth()}catch(_){}}
})();
