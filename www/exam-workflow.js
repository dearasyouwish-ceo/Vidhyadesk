window.VidyaExam=(()=>{
 async function createExam(db,row){const{data,error}=await db.from('exams').insert(row).select().single();if(error)throw error;return data}
 async function saveBatchMarks(db,{instituteId,examId,rows,enteredBy}){const payload=rows.map(r=>({institute_id:instituteId,exam_id:examId,student_id:r.studentId,marks:Number(r.marks||0),max_marks:Number(r.maxMarks||100),grade:r.grade||null,remarks:r.remarks||null,entered_by:enteredBy}));const{data,error}=await db.from('exam_marks').upsert(payload,{onConflict:'exam_id,student_id'}).select();if(error)throw error;return data}
 function calculate(marks){const max=marks.reduce((n,x)=>n+Number(x.max_marks||0),0),got=marks.reduce((n,x)=>n+Number(x.marks||0),0),pct=max?Math.round(got/max*10000)/100:0;const grade=pct>=90?'A+':pct>=80?'A':pct>=70?'B+':pct>=60?'B':pct>=50?'C':pct>=35?'D':'F';return{max,got,pct,grade,result:pct>=35?'PASS':'FAIL'}}
 async function result(db,{instituteId,examId,studentId}){const{data,error}=await db.from('exam_marks').select('*').eq('exam_id',examId).eq('student_id',studentId);if(error)throw error;return calculate(data||[])}
 return{createExam,saveBatchMarks,calculate,result};
})();