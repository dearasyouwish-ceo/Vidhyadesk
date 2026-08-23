window.VidyaLearning=(()=>{
 async function addLesson(db,row){const{data,error}=await db.from('course_lessons').insert(row).select().single();if(error)throw error;return data}
 async function publish(db,lessonId,published=true){const{data,error}=await db.from('course_lessons').update({status:published?'published':'draft'}).eq('id',lessonId).select().single();if(error)throw error;return data}
 async function progress(db,{instituteId,studentId,lessonId,completed,positionSeconds=0}){const{data,error}=await db.from('lesson_progress').upsert({institute_id:instituteId,student_id:studentId,lesson_id:lessonId,completed,position_seconds:positionSeconds,completed_at:completed?new Date().toISOString():null},{onConflict:'student_id,lesson_id'}).select().single();if(error)throw error;return data}
 async function note(db,row){const{data,error}=await db.from('lesson_notes').insert(row).select().single();if(error)throw error;return data}
 async function bookmark(db,row){const{data,error}=await db.from('lesson_bookmarks').upsert(row,{onConflict:'student_id,lesson_id'}).select().single();if(error)throw error;return data}
 return{addLesson,publish,progress,note,bookmark};
})();