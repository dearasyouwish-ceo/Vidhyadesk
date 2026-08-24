window.VidyaLearning=(()=>{
 async function addLesson(db,row){const{data,error}=await db.from('course_lessons').insert(row).select().single();if(error)throw error;return data}
 async function publish(db,lessonId,published=true){const{data,error}=await db.from('course_lessons').update({status:published?'published':'draft'}).eq('id',lessonId).select().single();if(error)throw error;return data}
 async function progress(db,{studentId,lessonId,completed=false,positionSeconds=0,progressPercent}){const{data,error}=await db.from('course_progress').upsert({student_id:studentId,lesson_id:lessonId,completed,progress_percent:Number(progressPercent??(completed?100:0)),last_position_seconds:Number(positionSeconds||0),updated_at:new Date().toISOString()},{onConflict:'lesson_id,student_id'}).select().single();if(error)throw error;return data}
 async function note(db,row){const{data,error}=await db.from('course_notes').insert(row).select().single();if(error)throw error;return data}
 async function bookmark(db,row){const{data,error}=await db.from('course_bookmarks').upsert(row,{onConflict:'lesson_id,student_id'}).select().single();if(error)throw error;return data}
 return{addLesson,publish,progress,note,bookmark};
})();