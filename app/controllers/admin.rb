class Admin < Application

  def index
    render
  end

  def upload    
    debugger
    if params[:file]
      file      = Upload.new(params[:file][:filename])      
      file.move(params[:file][:tempfile].path)
      Process.fork{
        `rake 'db:upload[#{file.directory}, #{file.filename}]'`
      }
      redirect "/admin/upload_status/#{file.directory}"
    else
      render
    end
  end

  def upload_status        
    render
  end
  
end


#      pf        = PatternFormatter.new(:pattern => "<b>[%l]</b> %m")
#       Merb.run_later do        
#         log       = Logger.new 'upload_log'
#         file_log  = Log4r::FileOutputter.new('output_log', :filename => [Merb.root, "public", "logs", file.directory].join("/"), :truncate => false, :formatter => pf)
#         log.add(file_log) 
#         log.level = INFO

#         log.info("File has been uploaded to the server. Now processing it into a bunch of csv files")
#         file.process_excel_to_csv
#         log.info("CSV extraction complete. Processing files.")
#         file.load_csv(log)
#         log.info("CSV files are now loaded into the DB. Creating loan schedules.")
#         `rake mock:update_history`
#         log.info("<h2>Processing complete! Your MIS is now ready for use. Please take a note of all the errors reported here(if any) and rectify them.</h2>")        
#       end
