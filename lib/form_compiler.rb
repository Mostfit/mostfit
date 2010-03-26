module CustomForm
  class Compiler
    attr_accessor :form_data, :filename, :new_properties, :form_name

    def initialize(model, _filename)
      @filename   = _filename
      @form_data  = YAML.load(File.read(File.join(Merb.root, "config", "forms", model, _filename)))
      @form_name = form_data[form_data.keys.first].keys.first
    end
    
    def compile
      new_properties = compile_model
      compile_form(new_properties)
      return true
    end

    private
    def compile_model
      new_properties, new_validations, new_fields = [], [], []
      properties = model.properties

      fields.each{|field|
        if field['type']=="table"
          emit_property(field).each{|new_prop|
            if not properties.find{|property| property.name==(new_prop.split(',')[0].split("property")[-1].strip[1..-1].to_sym)}
              new_properties  << new_prop
              new_validations << emit_validation(field)
              new_fields      << field
            end
          }
        elsif not properties.find{|property| property.name==field['name'].to_sym}
          new_properties  << emit_property(field)
          new_validations << emit_validation(field)
          new_fields      << field
        end
      }
      model_file_append(new_properties.compact)
      model_file_append(new_validations.flatten.compact)
      return fields
    end

    def compile_form(fields)
      haml_file =  ""
      haml_file << form_header
      fields.each{|field|
        haml_file += haml_row(field)
      }
      haml_file << hr
      create_view_file(haml_file)
    end
    
    def form_header
      header = []
      header << "%table"
      header << "  %tr"
      header << "    %td{:colspan => '2'}"
      header << "      %h1==#{form_name.humanize}"
      header.join("\n")+"\n"
    end

    def hr
      str = []
      str << "  %tr"
      str << "    %td{:colspan => '2'}"      
      str << "      %hr"
      str.join("\n")+"\n"
    end
    
    def haml_row(field)
      str  = []
      str << "  %tr"
      str << "    %td"
      str << "      #{field[:label]||field['name'].humanize}:"
      str << "    %td"
      str << "  " + emit_field(field)
      str << "      %br/"
      str << "      %span.greytext #{field['description']}" if field['description']
      str.join("\n")+"\n"
    end
    
    def emit_field(field)
      if field['type']=="text" and field['length'] and field['length'].to_i<100
        "    = text_field(:#{field['name']}, :size => #{field['length']})"
      elsif field['type']=="text"
        "    = text_area(:#{field['name']}, :rows => #{field['rows']||3}, :cols => #{field['columns']||20})"
      elsif field['type']=="integer"
        "    = text_field(:#{field['name']}, :size => #{field['length']||10})"
      elsif field['type']=="date"
        "    = date_select_for(#{form_object}, :#{field['name']})"
      elsif field['type']=="select_list"        
        collection = field['values'].map{|v| "[:#{v.to_s}, \"#{v.humanize}\"]"}.join(', ')
        "    = select(:#{field['name']}, :collection => [#{collection}] #{(", :prompt => \"" + field['default_value'] +"\"") if field['default_value']})"
      elsif field['type']=="check_list"
        str = []
        field['values'].each{|value|
          str << "    =check_box(:name => \"#{form_object[1..-1]}[#{field['name']}]\", :value => \"#{value}\", :label => \"#{value.humanize}\")"
        }
        return str.join("\n")
      elsif field['type']=="table"
        emit_table(field).collect{|l|
          "    #{l}"
        }.join("\n")
      end
    end

    def emit_table(field)
      str = []
      get_columns(field).each_with_index{|colgroup, idx|
        str << compile_table(field, colgroup, idx)
      }
      str.flatten
    end
    
    def compile_table(field, colgroup, row_num)
      table =  []
      if row_num == 0
        table << "%table{:width => '100%'}"
        if field['rows'] #Emitting header
          table << "  %tr"
          table << "    %th"
          field["columns"].each{|row|
            table << "    %th"
            table << "      #{row}"
          }
        end
      end

      if field['rows'] 
        # Emit first row as column names
        table << "  %tr"
        table << "    %td"
        table << "      #{field['rows'][row_num][0].humanize}"
      else
        table << "  %tr"
        colgroup.each{|column|
          table << "    %td"
          table << "      #{column.to_a.flatten[0].humanize}"          
          #        table[-1]+="(#{opts['label']})" if opts and opts['label']
        }
        table << "  %tr"
      end

      colgroup.each{|column|        
        table << "    %td"
        table << "  #{emit_field(column.values[0])}"
      }
      table
    end
    
    def get_columns(field)
      return [] if field['columns'].nil?
      return get_columns_with_rows(field) if field['rows']
      colgroups = []
      colgroups << field['columns'].sort if field['columns'].is_a? Hash
      colgroups =  field['columns'] if field['columns'].is_a? Array
      colgroups.each{|colgroup|
        colgroup.each{|column|
          column[column.keys.first]=get_column_opts(field, column.keys.first)
        }
      }
      colgroups
    end

    def get_columns_with_rows(field)
      return [] if field['columns'].nil?
      return [] if field['rows'].nil?
      columns, rows = [], []
      columns << field['columns'].sort    if field['columns'].is_a? Hash
      columns =  field['columns'].flatten if field['columns'].is_a? Array
      rows    << field['rows'].sort       if field['rows'].is_a? Hash
      rows    =  field['rows'].flatten    if field['rows'].is_a? Array
      colgroups = []; 
      rows.each{|row| 
        colgroups.push([])
        columns.each{|column|
          colgroups.last.push({"#{column}_#{row}" => get_column_opts(field, "#{column}_#{row}")})
        }
      }
      colgroups
    end
  
    def get_column_opts(field, column)
      column_name, column_opts = column
      opts  = column_opts||{}
      opts['name'] = field['name']+'_'+column_name.to_s
      opts['type'] = (column_opts and column_opts['type']) ? column_opts['type'] : field['column_type']
      ['length', 'default', 'minimum', 'maximum','validations'].each{|x| 
        opts[x] = (column_opts and column_opts[x])||field[x]
      }
      opts
    end
    
    def create_view_file(content)
      File.open(model_view_file_name, "a"){|f|
        f.puts content
      }
    end

    #Emit properties after getting them compiled. For tables it is a little complicated than that
    def emit_property(field)
      if field['type']=="table"
        str = []
        get_columns(field).flatten.each{|colgroup|
          colgroup.values.each{|col|
            str << compile_property(col)
          }
        }
        return(str)
      else
        return(compile_property(field))
      end
    end
    
    # Compile property for a given field. Should look like
    # property :<field_name>, <type>, :length => <length>, :default => <default>
    def compile_property(field)
      new_property = "  property :#{field['name']}, #{find_type(field)}"
      new_property += ", :length => #{field['length']}" if field['length']
      new_property += ", :default => #{field['default']}" if field['default'] and not field['default'].blank?
      if field['validations'] and field['validations'].key?('required')
        new_property += ", :nullable => #{field['validations']['required'] ? 'false' : 'true'}"
      end
      new_property
    end

    def emit_validation(field)
      if field['type']=="table"
      else
        return(compile_validation(field))
      end
    end

    #Create validations for a given field
    def compile_validation(field)
      new_validation = []
      if field['validations']
        new_validation << " validates_present #{field['name']}" if field['validations']['required'] and field['validations']['required']=='true'
        if field['validations']['minimum'] or  field['validations']['maximum']
          new_validation << "  validates_length :#{field['name']}" 
          if field['validations']['minimum'] and not (field['validations'] and not field['validations']['required'])
            new_validation[-1] += ", :min => #{field['validations']['minimum']}"
          end
          new_validation[-1] += ", :max => #{field['validations']['maximum']}" if field['validations']['maximum']
        end
      end
      new_validation.length>0 ? new_validation : nil
    end
    
    #get model for a given form data
    def model
      Kernel.const_get(form_data.keys[0].singularize.capitalize)
    end
    
    def form_object
      "@#{form_data.keys[0].singularize}"
    end
    
    def model_file_name
      File.join(Merb.root, "app", "models", model.to_s.downcase+".rb")
    end

    def model_view_file_name
      File.join(Merb.root, "app", "views", model.to_s.downcase.pluralize, "_#{form_name}.html.haml")
    end
    
    def model_file
      File.open(model_file_name).readlines
    end
    
    # Write property and validations to a model after the last property in that class. 
    def model_file_append(arr)
      last_property_line = 1
      orig_file =  model_file
      
      #Last propery line number
      orig_file.each_with_index{|line, idx|
        last_property_line = idx+1 if /^property\.*/.match(line.strip)
      }
      
      f = File.open(model_file_name, "w")
      f.puts(orig_file[0..last_property_line-1])
      arr.each{|line|
        f.puts line
      }
      f.puts(orig_file[last_property_line..-1])
      f.close
    end
    
    #Get the fields sorted by position
    def fields
      form_data[form_data.keys.first][form_name].collect{|k, v| v["name"] = k; v }.sort_by{|x| x["position"]}
    end

    #Fidn the DM property for a given field type
    def find_type(field)
      type = field['type']
      if    type=="text" and field['length']
        return "String"
      elsif type=="text" and not field['length']
        return "Text"
      elsif ["date", "integer", "float"].include?(type)
        return type.capitalize
      elsif type=="select_list"        
        arr   = "'" + field['values'].join("', '") + "'"
        arr   = "'', #{arr}" if field['validations'] and field['validations'].key?('required') and not field['validations']['required']
        str   = "Enum.send('[]', *[#{arr}])"
        str   = "#{str}, :default => ''" if field['validations'] and field['validations'].key?('required') and not field['validations']['required']
        return str
      elsif type=="table"
        return "String"
      elsif type=="check_list"
        return "Flag[:#{field['values'].join(', :')}]"
      end
    end    
  end
  
  class HamlCompiler
    def tr
      "%tr"
    end
  end

end
