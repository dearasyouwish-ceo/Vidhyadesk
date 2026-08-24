window.VidyaSmokeTest=(()=>{
 const modules=['VidyaFeeEngine','VidyaFeeWorkflow','VidyaFamily','VidyaAttendance','VidyaExam','VidyaLearning','VidyaPortal','VidyaPayroll','VidyaLeads','VidyaPrint','VidyaNotify','VidyaSecurity','VidyaOffline','VidyaReleaseGate'];
 function run(){const result=Object.fromEntries(modules.map(k=>[k,typeof window[k]!=='undefined']));result.title=document.title==='VidyaDesk';result.app=!!document.getElementById('app');result.pass=Object.values(result).every(Boolean);console.table(result);return result}
 return{run};
})();