desc "This will update students lists and MVR status"
task update_students: :environment do
  include ApplicationHelper
  @log = ApiLog.new
  api = UpdateStudentsApi.new
  @log.api_logger.info "#{Date.today}"

  @log.api_logger.info "Update students lists ******************************"
  programs = Program.current_term.where(not_course: false)
  programs.each do |program|
    @log.api_logger.info "#{program.title} program updated"
    api.update_students(program, @log)
  end

  @log.api_logger.info "Update students MVR status ***********************************"
  programs = Program.current_term
  programs.each do |program|
    program.students.each do |student|
      if need_to_check_mvr_status?(student)
        status = api.mvr_status(student.uniqname)
        student.update(mvr_status: status)
      end
    end
    @log.api_logger.info "#{program.title} program updated"
  end

  @log.api_logger.info "Update managers MVR status ***********************************"
  managers = Manager.all
  managers.each do |manager|
    status = api.mvr_status(manager.uniqname)
    manager.update(mvr_status: status)
  end

  @log.api_logger.info "Update Canvas courses status ***********************************"
  programs = Program.current_term
  programs.each do |program|
    @log.api_logger.info "#{program.title} program updated"
    api.update_canvas_results(program, @log)
  end

end
