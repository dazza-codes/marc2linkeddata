#!/usr/bin/env ruby

module Marc2LinkedData

  class Utils

    def self.stack_trace(e, data=nil)
      $stderr.write "\n"
      $stderr.write "ERROR\n"
      $stderr.write e.message
      $stderr.write e.backtrace
      $stderr.write "\n"
      unless data.nil?
        $stderr.write data.to_s
        $stderr.write "\n"
      end
    end

    # def marc_record_cache(record_file, record_id, record_data=nil)

    #   # # TODO: enable additional persistence options
    #   # # Use data already in redis (if enabled)
    #   # triples = CONFIG.redis.get(auth_id) if CONFIG.redis_read
    #   # if triples.nil?
    #   #   triples = auth.to_ttl  # generate new triples
    #   #   # Update redis (if enabled) for triples not read from redis
    #   #   CONFIG.redis.set(auth_id, triples) if CONFIG.redis_write
    #   # end

    # end

    # Memory intensive loading of all authority records in the MARC file.
    def self.marc_read_records(marc_filepath, record_types=[])
      config = Marc2LinkedData.configuration
      marc_filepath = File.realpath(marc_filepath)
      marc_file = File.open(marc_filepath,'r')
      puts "Reading records from: #{marc_filepath}"
      record_count = 0
      records = []
      until marc_file.eof?
        begin
          # marc_parse_leader reads leader and then rewinds to begining of record.
          leader = marc_parse_leader(marc_file)
          if record_types.include? leader[:type]
            raw = marc_file.read(leader[:length])
            record = {
              :filepath => marc_filepath,
              :type => leader[:type],
              :offset => leader[:offset],
              :marc => MARC::Reader.decode(raw)
            }
            records << record
            record_count += 1
            $stdout.printf "\b\b\b\b\b\b" if record_count > 1
            $stdout.printf '%06d', record_count
            break if (config.test_records > 0 && config.test_records <= record_count)
          else
            marc_file.seek(leader[:length], IO::SEEK_CUR)
          end
        rescue => e
          stack_trace(e, record)
          binding.pry if CONFIG.debug
        end
      end
      marc_file.close
      $stdout.write "\n"
      records
    end

    # Count all the records in the MARC file
    def self.marc_authority_count(marc_filepath)
      record_types = marc_type_info(marc_filepath)
      record_types.each_value {|v| v.delete :offsets }
      record_types[:z]
    end

    # read all the authority records (or LIMIT_RECORDS)
    def self.marc_authority_records(marc_filepath)
      records = marc_read_records(marc_filepath,['z'])
      records.collect {|r| Marc2LinkedData::ParseMarcAuthority.new(r)}
    end

    def self.marc_authority_file_search(marc_filepath, opts={})
      marc_filepath = File.realpath(marc_filepath)
      record_results = {
        :filename => marc_filepath,
        :search_params => opts,
        :search_results => []
      }
      begin
        auth_records = marc_authority_records(marc_filepath)
        # progress = ProgressBar.create(:total => auth_records.length, :format => '%a %f |%b>>%i| %P%% %t')
        auth_records.each do |auth|
          result = marc_authority_record_search(auth, opts)
          record_results[:search_results] << result unless result.empty?
          # progress.increment  # it's so fast that progress is not required
        end
        # if CONFIG.threads
        #   # Allow Parallel to automatically determine the optimal concurrency model.
        #   # Note that :in_threads crashed and :in_processes worked.
        #   # Parallel.each(auth_records, :progress => 'Records: ', :in_threads=>CONFIG.thread_limit) do |r|
        #   # Parallel.each(auth_records, :progress => 'Records: ', :in_processes=>CONFIG.thread_limit) do |r|
        #   Parallel.each(auth_records, :progress => 'Records: ') do |r|
        #     result = marc_authority_record_search(r, opts)
        #   end
        # end
      rescue => e
        stack_trace(e)
        binding.pry if CONFIG.debug
      end
      record_results
    end

    def self.marc_authority_record_search(auth, opts={})
      record_result = {}
      search_result = {}
      begin
        if opts[:id]
          id = auth.get_id
          search_result[:id] = id if id.include? opts[:id]
        end
        if opts[:name]
          name = auth.get_name
          unless name.nil?
            search_result[:name] = name if name.include? opts[:name]
          end
        end
        if opts[:first_name]
          fn = auth.get_first_name
          unless fn.nil?
            search_result[:first_name] = fn if fn.include? opts[:first_name]
          end
        end
        if opts[:last_name]
          ln = auth.get_last_name
          unless ln.nil?
            search_result[:last_name] = ln if ln.include? opts[:last_name]
            binding.pry if ln.include? opts[:last_name]
          end
        end
        # TODO: Enable additional types of search?
        unless search_result.empty?
          if opts[:logical_operator] == 'AND'
            opt_keys = opts.keys
            opt_keys.delete :logical_operator
            if search_result.keys == opt_keys
              record_result[:record_id] = auth.get_id
              record_result[:record_offset] = auth.record[:offset]
              record_result[:search_result] = search_result
            end
          else
            record_result[:record_id] = auth.get_id
            record_result[:record_offset] = auth.record[:offset]
            record_result[:search_result] = search_result
          end
        end
      rescue => e
        stack_trace(e, auth.record)
        binding.pry if CONFIG.debug
      end
      record_result
    end

    def self.marc_parse_leader(file_handle, leader_bytes=24)
      # example:
      #record.leader
      #=> "00774cz  a2200253n  4500"
      # 00-04: '00774' - record length
      # 05:    'c' - corrected or revised
      # 06:    'z' - always 'z' for authority records
      # 09:    'a' - UCS/Unicode
      # 12-16: '00253' - base address of data, Length of Leader and Directory
      # 17:    'n' - Complete authority record
      # leader_status_codes = {
      #     'a' => 'Increase in encoding level',
      #     'c' => 'Corrected or revised',
      #     'd' => 'Deleted',
      #     'n' => 'New',
      #     'o' => 'Obsolete',
      #     's' => 'Deleted; heading split into two or more headings',
      #     'x' => 'Deleted; heading replaced by another heading'
      # }
      offset = file_handle.tell
      leader = file_handle.read(leader_bytes)
      file_handle.seek(-1 * leader_bytes, IO::SEEK_CUR)
      {
        :offset => offset,
        :length => leader[0..4].to_i,
        :status => leader[5],    # leader_status_codes[ record.leader[5] ]
        :type => leader[6],
        :encoding => leader[9],  # translate letter code into ruby encoding string
        :data_address => leader[12..16].to_i,
        :complete => leader[17].include?('n')
      }
    end


    # Count all the records in the MARC file
    def self.marc_type_count(marc_filepath)
      record_types = marc_type_info(marc_filepath)
      record_types.each_value {|v| v.delete :offsets }
    end

    def self.marc_type_init(label)
      {
        :label => label,
        :count => 0,
        :offsets => []
      }
    end

    # Gather record type information by parsing the record leader, see
    # http://www.loc.gov/marc/bibliographic/bdleader.html
    # http://www.loc.gov/marc/authority/adleader.html
    def self.marc_type_info(marc_filepath)
      # 06 - Type of record
      # a - Language material
      # c - Notated music
      # d - Manuscript notated music
      # e - Cartographic material
      # f - Manuscript cartographic material
      # g - Projected medium
      # i - Nonmusical sound recording
      # z - Authority data
      record_types = {
        :a => marc_type_init('language_material'),
        :c => marc_type_init('notated_music'),
        :d => marc_type_init('manuscript_notated_music'),
        :e => marc_type_init('cartographic_material'),
        :f => marc_type_init('manuscript_cartographic_material'),
        :g => marc_type_init('projected_medium'),
        :i => marc_type_init('nonmusical_sound_recording'),
        :z => marc_type_init('authority_data'),
      }
      marc_file = File.open(marc_filepath,'r')
      until marc_file.eof?
        begin
          offset = marc_file.pos
          leader = marc_parse_leader(marc_file)
          marc_file.seek(leader[:length], IO::SEEK_CUR)
          type = leader[:type].to_sym
          record_types[type][:count] += 1
          record_types[type][:offsets] << offset
        rescue => e
          stack_trace(e, leader)
          binding.pry if CONFIG.debug
        end
      end
      marc_file.close
      record_types
    end


  end

end
