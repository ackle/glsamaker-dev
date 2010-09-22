class CveController < ApplicationController
  before_filter :login_required
  include ApplicationHelper

  def index
    @pageID = 'cve'
  end

  def list
    @pageID = 'cve'
    @cves = CVE.find(:all, :conditions => ['state = ?', 'NEW'], :limit => 100)

    respond_to do |format|
      format.html
      format.json {
        x = @cves.map {|cve| [cve.id, cve.cve_id, cve.summary, cve.state]}
        render :text => x.to_json }
    end
  end

  def info
    @cve = CVE.find(:first, :conditions => ['cve_id = ?', params[:id]])
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def show
  end

  def store
  end

  def bug_package
    cve_nums = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "File new Bug; CVElist: " + cve_nums.inspect }

    cves = cve_nums.map {|c| CVE.find(c) }
    cpes = cves.map {|c| c.cpes.map{|cpe| cpe.product } }.flatten.uniq
    
    package_hints = cves.map{|c| c.package_hints }.flatten.uniq.sort
    logger.debug { "CPE Products: " + cpes.inspect }
    logger.debug { "Package hints: " + package_hints.inspect }
    
    logger.debug { {:package_hints => package_hints}.to_json }
    render :json => {:package_hints => package_hints}.to_json
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def bug_preview
    cve_nums = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "File new Bug (preview); CVElist: " + cve_nums.inspect }

    @cve_ids = cve_nums.map {|c| CVE.find(c).cve_id }
    @cve_txt = CVE.concat(cve_nums)
    @package = params[:package]
    @maintainers = Glsamaker::Portage.get_maintainers(params[:package])
    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500    
  end
  
  def bug
    # {"add_cves"=>"1", "comment"=>"", "wb_1"=>"A1", "cves"=>"200", "wb_2"=>"[ebuild]", "action"=>"bug", "wb_ext"=>"", 
    # "bug_title"=>"dev-perl/HTTP-Server-Simple: Unspecified vulnerability (CVE-2004-0113)", "bug_type"=>"true", 
    # "controller"=>"cve", "_"=>"", "cc_custom"=>"", "add_comment"=>"1", "cc_maint"=>"true"}
    cve_nums = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "File new Bug (final); CVElist: " + cve_nums.inspect }

    cves = cve_nums.map {|c| CVE.find(c) }
    
    data = {
      :product => 'Gentoo Security',
      :component => params[:bug_type] == 'true' ? 'Vulnerabilities' : 'Kernel',
      :summary => params[:bug_title],
      :assignee => 'security@gentoo.org',
    }
    
    cc = []
    if params[:cc_maint] == 'true'
      cc << Glsamaker::Portage.get_maintainers(params[:package])
    end
    
    cc << params[:cc_custom].split(',')
    data[:cc] = cc.join(',')
    
    comment = ""
    if params[:add_cves] == 'true'
      comment += CVE.concat(cve_nums)
    end
    
    if params[:add_comment] == 'true'
      comment += "\n"
      comment += params[:comment]
    end
    data[:comment] = comment
    
    whiteboard = "%s %s" % [params[:wb_1], params[:wb_2]]
    whiteboard += " %s" % params[:wb_ext] unless params[:wb_ext] == ""
    
    bugnr = -1
    begin
      bugnr = Bugzilla.file_bug(data)
      Bugzilla.update_bug(bugnr, {:whiteboard => whiteboard})
    rescue Exception => e
      raise "Filing the bug failed. Check if the accounts in CC actually exist."
    end
    
    logger.info "Filed bug #{bugnr} on behalf of user #{current_user.login}."
    
    cves.each do |cve|
      a = cve.assignments.new
      a.bug = bugnr
      a.save!
      
      ch = cve.cve_changes.new
      ch.user = current_user
      ch.action = 'file'
      ch.object = a.id
      ch.save!
      
      cve.state = 'ASSIGNED'
      cve.save!
    end
    
    render :text => 'ok'
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500    
  end

  def assign_preview
    bug_id = Integer(params[:bug])
    cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "Assign Bug: #{bug_id} CVElist: " + cves.inspect }

    cve_ids = cves.map {|c| CVE.find(c).cve_id }
    logger.debug { cve_ids.inspect }

    @cve_txt = CVE.concat(cves)
    @bug = Glsamaker::Bugs::Bug.load_from_id(bug_id)
    @summary = cveify_bug_title(@bug.summary, cve_ids)

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def assign
    bug_id = Integer(params[:bug])
    cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "Assign Bug: #{bug_id} CVElist: " + cves.inspect }

    cves.each do |cve_id|
      cve = CVE.find cve_id
      assi = cve.assignments.new
      assi.bug = bug_id
      assi.save!

      ch = cve.cve_changes.new
      ch.user = current_user
      ch.action = 'assign'
      ch.object = assi.id
      ch.save!

      cve.state = "ASSIGNED"
      cve.save!
    end

    if params[:comment] or params[:summary]
      bug = Glsamaker::Bugs::Bug.load_from_id(bug_id)
      cve_ids = cves.map {|c| CVE.find(c).cve_id }
      changes = {}

      changes[:comment] = CVE.concat(cves) if params[:comment]
      changes[:summary] = cveify_bug_title(bug.summary, cve_ids)
      Bugzilla.update_bug(bug_id, changes)
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def nfu
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "NFU CVElist: " + @cves.inspect + " Reason: " + params[:reason] }

    @cves.each do |cve_id|
      cve = CVE.find(cve_id)
      raise unless cve

      cve.state = "NFU"
      cve.save!

      ch = cve.cve_changes.new
      ch.user = current_user
      ch.action = 'nfu'
      ch.object = params[:reason] if params[:reason] and not params[:reason].empty?
      ch.save!
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def commit
  end

end
