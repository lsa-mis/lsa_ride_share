desc "This will edit database adding courses to programs"
task add_courses_to_programs: :environment do

  programs = Program.where(not_course: false)
  edited_programs = []
  failed_programs = []
  updated_courses_students = []
  failed_courses_students = {}
  programs.each do |program|
    if program.subject.present?
      course = Course.new(subject: program.subject, catalog_number: program.catalog_number, class_section: program.class_section, program_id: program.id)
      if course.save
        edited_programs << program.id
        program.update(subject: nil, catalog_number: nil, class_section: nil)
        failed_students = []
        program.students.each do |student|
          unless student.update(course_id: course.id)
            failed_students << student.id
          end
        end
        if failed_students.count == 0
          updated_courses_students << course.id
        else
          failed_courses_students[course.id] = failed_students
        end
      else 
        failed_programs << program.id
      end
    end
  end
  puts "Courses were created for the following programs: "  + edited_programs.join(", ")
  puts "Courses were not created for the following programs: "  + failed_programs.join(", ")
  puts "Students lists were updated for courses: " + updated_courses_students.join(", ")
  if failed_courses_students.count > 0 
    puts "Students records were not updated for course_id => student ids: "
    puts failed_courses_students
  end
end