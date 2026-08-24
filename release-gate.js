window.VidyaReleaseGate=(()=>{
 const required=['fee-engine.js','fee-workflow.js','family-receipts.js','attendance-workflow.js','exam-workflow.js','learning-workflow.js','portal-workflow.js','payroll-workflow.js','leads-reports.js','print-utils.js','notifications-export.js','security-utils.js','offline-sync.js'];
 function check(){return {brand:document.title==='VidyaDesk',supabase:!!window.supabase,modules:required.map(x=>({file:x,loaded:[...document.scripts].some(s=>s.src.endsWith('/'+x))})),offline:!!window.VidyaOffline,security:!!window.VidyaSecurity,fee:!!window.VidyaFeeEngine,portal:!!window.VidyaPortal};}
 function ok(){const x=check();return x.brand&&x.supabase&&x.modules.every(m=>m.loaded)&&x.offline&&x.security&&x.fee&&x.portal}
 function diagnostics(){const x=check();console.table(x.modules);return x}
 return{check,ok,diagnostics};
})();